#!/usr/bin/env python

import requests
import xml.etree.ElementTree as ET
from datetime import datetime
from datetime import timedelta

HOST="127.0.0.1"
PROTOCOL="http"
PORT=8083

STATUS = {"success" : 0,
    "warning" : 1,
    "error" : 2,
     }

OUTPUT_FORMAT = "{status} {entity} - {message}"

def get_time(micsecs):
    utc_time = datetime(1970, 1, 1) + timedelta(milliseconds=int(micsecs)/1000)
    return utc_time

class Base(object):
    @classmethod
    def get_resource_list(cls, response, resource_name):
        result = []
        root = ET.fromstring(response.text)
        elem = root.find(resource_name)
        if elem is not None:
            elem = elem.find("list")
            if elem is not None:
                for child in elem:
                    data = {}
                    for c in child:
                        data[c.tag] = c.text
                    result.append(data)
        return result

    @classmethod
    def make_request(cls, action):
        res = requests.get("{protocol}://{host}:{port}/{action}".\
                    format(protocol=PROTOCOL, host=HOST, port=PORT,action=action))
        return res

class XmppServer(Base):
    @classmethod
    def get_xmpp_server_stat(cls):
        action = "Snh_ShowXmppServerReq"
        result = {}
        current_connections = 0
        max_connections = 0
        status = 0
        msg = ""
        res = cls.make_request(action)
        if not res.status_code in [200]:
            raise Exception("status_code:{status_code}, reason:{reason}".format(status_code=res.status_code, reason=res.reason))
        else:
            root = ET.fromstring(res.text)
            e_current_connections = root.find("current_connections")
            if e_current_connections is not None:
                current_connections = e_current_connections.text
            e_max_connections = root.find("max_connections")
            if e_max_connections is not None:
                max_connections = e_max_connections.text
            if current_connections >= max_connections:
                msg = "CRITICAL: " + "current_connections:{c_conn} max_connections:{m_conn}".\
                    format(c_conn=current_connections, m_conn=max_connections)
                status = STATUS.get("warning")
            else:
                msg = "OK: " + "current_connections:{c_conn} max_connections:{m_conn}".\
                    format(c_conn=current_connections, m_conn=max_connections)
                status = STATUS.get("success")
            return OUTPUT_FORMAT.format(status=status, entity="XMPP:Server", message=msg)

    @classmethod
    def get_disconnected_xmpp_peers(cls):
        action = "Snh_SandeshUVECacheReq"
        result = []
        res = cls.make_request(action+"?x=XmppPeerInfoData")
        if not res.status_code in [200]:
            raise Exception("status_code:{status_code}, reason:{reason}".format(status_code=res.status_code, reason=res.reason))
        else:
            root = ET.fromstring(res.text)
            peer_infos = root.findall("XMPPPeerInfo")
            peers_list = []
            for peer_info in peer_infos:
                e_data = peer_info.find("data")
                e_peer_info_data = e_data.find("XmppPeerInfoData")
                e_identifier = e_peer_info_data.find("identifier")
                if e_identifier is not None:
                    e_name = e_peer_info_data.find("name")
                    peer_name = e_identifier.text
                    if e_name is not None:
                        peer_name = "{name}({ip})".format(name=peer_name,ip=e_name.text.split(":")[1])
                    e_send_state = e_peer_info_data.find("send_state")
                    send_state_text = e_send_state.text
                    e_deleted = e_peer_info_data.find("deleted")
                    e_state_info = e_peer_info_data.find("state_info")
                    e_peer_state_info = e_state_info.find("PeerStateInfo")
                    e_state = e_peer_state_info.find("state")
                    state_text = e_state.text
                    e_event_info = e_peer_info_data.find("event_info")
                    e_peer_event_info = e_event_info.find("PeerEventInfo")
                    e_last_event = e_peer_event_info.find("last_event")
                    e_last_event_at = e_peer_event_info.find("last_event_at")
                    last_event_text = e_last_event.text
                    last_event_at_text = e_last_event_at.text
                    if e_deleted is not None:
                        status = STATUS.get("error")
                        msg = "WARNING: " + "Peer:'{name}', State:'{state}, {send_state}', LastEvent:{last_event}, LastEventAt={last_event_at}".\
                        format(name=peer_name, state=state_text, send_state=send_state_text, last_event=last_event_text, last_event_at=get_time(last_event_at_text))
                        result.append(OUTPUT_FORMAT.format(status=status,
                            entity="XMPP:Peer", message=msg))
        return result


class BgpPeer(Base):
    @classmethod
    def get_bgp_neighbors(cls):
        #stop one contrail-control service to test it.
        action = "Snh_BgpNeighborReq"
        attrs = {"state" : {"exp_value":"Established"},
			"send_state" : {"exp_value":"in sync"}}
        result = []
        res = cls.make_request(action)
        if not res.status_code in [200]:
            raise Exception("status_code:{status_code}, reason:{reason}".format(status_code=res.status_code, reason=res.reason))
        else:
            rlist = cls.get_resource_list(res, "neighbors")
            connected_xmpp_peers = []
            connected_bgp_peers = []
            for r in rlist:
                peer_name = "{name}({ip})".format(name=r.get("peer", ""), ip=r.get("peer_address",""))
                if r.get("encoding") in ["BGP"]:
                    connected_bgp_peers.append(peer_name)
                elif r.get("encoding") in ["XMPP"]:
                    connected_xmpp_peers.append(peer_name)
                if r.get("state") not in attrs["state"]["exp_value"] or r.get("send_state") not in attrs["send_state"]["exp_value"]:
                    status = STATUS.get("error")
                    msg = "CRITICAL: " + "Peer:'{name}', State:'{state}, {send_state}', LastEvent:'{last_event}', LastStateAt:{last_state_at}'.".\
                            format(name=peer_name, state=r.get("state",""), send_state=r.get("send_state",""), last_event=r.get("last_event",""),
                                last_state_at=r.get("last_state_at",""))
                else:
                    status = STATUS.get("success")
                    msg = "OK: " + "Peer:'{name}', State:'{state}, {send_state}', LastEvent:'{last_event}', LastStateAt:{last_state_at}'.".\
                            format(name=peer_name, state=r.get("state",""), send_state=r.get("send_state",""), last_event=r.get("last_event",""),
                                last_state_at=r.get("last_state_at",""))
                result.append(OUTPUT_FORMAT.format(status=status, entity="{encoding}:peer".format(encoding=r.get("encoding")), message=msg))
            if not connected_bgp_peers:
                status = STATUS.get("error")
                msg = "CRITICAL: " + "Could not find BGP Peers"
            else:
                status = STATUS.get("success")
                msg = ",".join(connected_bgp_peers)
            result.append(OUTPUT_FORMAT.format(status=status, entity="BGP:Peers", message=msg))
            if not connected_xmpp_peers:
                status = STATUS.get("error")
                msg = "CRITICAL: " + "Could not find XMPP Peers"
            else:
                status = STATUS.get("success")
                msg = ",".join(connected_xmpp_peers)
            result.append(OUTPUT_FORMAT.format(status=status, entity="XMPP:Peers", message=msg))
        return result


class Ifmap(Base):
    @classmethod
    def get_ifmap_connection_status(cls):
        action = "Snh_IFMapPeerServerInfoReq"
        result = []
        host = ""
        conn_sttaus = ""	
        res = cls.make_request(action)
        if not res.status_code in [200]:
            raise Exception("status_code:{status_code}, reason:{reason}".format(status_code=res.status_code, reason=res.reason))
        else:
            root = ET.fromstring(res.text)
            e_server_conn_info = root.find("server_conn_info")
            if e_server_conn_info is not None:
                e_ifmap_peer_server_conn_info = e_server_conn_info.find("IFMapPeerServerConnInfo")
                if e_ifmap_peer_server_conn_info is not None:
                   e_connection_status = e_ifmap_peer_server_conn_info.find("connection_status")
                   if e_connection_status is not None:
                       conn_status = e_connection_status.text
                   e_host = e_ifmap_peer_server_conn_info.find("host")
                   if e_host is not None:
                       host = e_host.text
                   if conn_status and host:
                       if "Up" in conn_status:
                          monit_status_msg = "OK"
                          monit_status = STATUS.get("success")
                       else:
                          monit_status_msg = "CRITICAL"
                          monit_status = STATUS.get("error")
                       msg = "{monit_status_msg}: Connection to Ifmap Server:{host} {conn_status}".\
                               format(monit_status_msg=monit_status_msg, host=host, conn_status=conn_status)
                       return OUTPUT_FORMAT.format(status=monit_status, entity="IFMAP:Connection", message=msg)

if __name__ == "__main__":
    pipe = [XmppServer.get_xmpp_server_stat,
        XmppServer.get_disconnected_xmpp_peers,
        BgpPeer.get_bgp_neighbors,
        Ifmap.get_ifmap_connection_status,
       ]
    for fun in pipe:
        res = None
        try:
            res = fun()
        except Exception as ex:
            print OUTPUT_FORMAT.format(status=STATUS.get("error"), entity="Monitoring Script", 
                message="Failed:{script}, {reason}".format(script=fun.__name__, reason=str(ex)))
        if res:
            if isinstance(res, list):
                for r in res:
                    print r
            else:
                print res








