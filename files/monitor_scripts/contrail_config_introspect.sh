#!/usr/bin/env python
import telnetlib
import jpype
from jpype import java
from jpype import javax
import subprocess

SUCCESS = 0
FAIL 	= 1

HOST    = "127.0.0.1"

#Zookeeper constants
ZKPORT      = 2181
ZKWARNLAT   = 500
ZKCRITLAT   = 2000
ZKWARNREQ   = 5000
ZKCRITREQ   = 10000
ZKLDRELPRT  = 3888
ZKLDRCONPRT = 2888

#Cassandra constants
CASSPORT            =7199
CASSUSER            =''
CASSPASS            =''
CASSPARNEWWARN      = 2000000
CASSPARNEWCRIT      = 5000000
CASSCMSWARN         = 2000000
CASSCMSCRIT         = 5000000
CASSPENDINGWARN     = 10000
CASSPENDINGCRIT     = 50000
CASSKEYCACHEWARN    = 1/0.85
CASSKEYCACHECRIT    = 1/0.75
CASSLATWARN         = 2000000.0
CASSLATCRIT         = 5000000.0
CASSCLUSTERSIZE     = 3

#Status mapping
STATUS = {  "success" : 0,
  	        "warning" : 1,
	        "critical" : 2,
	     }

# Format specifications
OUTPUT_FORMAT   = "{status} {entity} - {message}"
PERF_FORMAT     = "{type}={value};{warning};{critical}"
OUTPERF_FORMAT  = "P {entity} {perf} {message}" 

class Netstat(object):
    @classmethod
    def tcp_check(cls, port):
        cmd = 'netstat -t --numeric-hosts | grep ":{} "'.format(str(port))
        return subprocess.check_output(cmd,shell=True)

#Telnet class
class Tel(object):
    def __init__(self, host, port):
        self.obj = telnetlib.Telnet(host, port)

    def request(self, cmd):
        self.obj.write(cmd)
        return self.obj.read_all()

#JMX class
class JMXConnector(object):
    def __init__(self, host, port, user, passwd):
        URL = "service:jmx:rmi:///jndi/rmi://%s:%d/jmxrmi" % (host, port)
        jpype.startJVM("/usr/lib/jvm/default-java/jre/lib/amd64/server/libjvm.so")
        jhash = java.util.HashMap()
        jarray=jpype.JArray(java.lang.String)([user,passwd])
        jhash.put (javax.management.remote.JMXConnector.CREDENTIALS, jarray);
        jmxurl = javax.management.remote.JMXServiceURL(URL)
        jmxsoc = javax.management.remote.JMXConnectorFactory.connect(jmxurl,jhash)
        self.connection = jmxsoc.getMBeanServerConnection();

    def get_attr(self, object, attribute):
        return self.connection.getAttribute(javax.management.ObjectName(object),attribute)

class CassMonitor(object):
    def __init__(self):
        try:
            self.cassobj = JMXConnector(HOST, CASSPORT, CASSUSER, CASSPASS)
            self.ready = True
        except Exception as ex:
            self.ready = False
            status = STATUS.get("critical")
            msg = "CRITICAL: "+"Not able to connect to Cassandra JMX. Reason : "+str(ex)
            print OUTPUT_FORMAT.format(status=status, entity="Cassandra:JMX", message=msg)

    def get_attr(self, object, attribute):
        return self.cassobj.get_attr(object, attribute)
        
    def CassMntrGc(self):
        res = list()
        if self.ready == False:
            return
        parnewtime = self.get_attr("java.lang:type=GarbageCollector,name=ParNew",
                                   "CollectionTime")
        perf = PERF_FORMAT.format(type="parnewgc_time", value=parnewtime,
                                  warning=CASSPARNEWWARN, critical=CASSPARNEWCRIT)
        msg = "GC:Par new time"
        res.append(OUTPERF_FORMAT.format(entity="Cassandra:PNTime", perf=perf, message=msg))
        
        cmstime = self.get_attr("java.lang:type=GarbageCollector,name=ConcurrentMarkSweep",
                                "CollectionTime")
        perf = PERF_FORMAT.format(type="cmsgc_time", value=cmstime, warning=CASSCMSWARN,
                                  critical=CASSCMSCRIT)
        msg = "GC:CMS time"
        res.append(OUTPERF_FORMAT.format(entity="Cassandra:CMSTime", perf=perf, message=msg))	

        return res

    def CassMntrCompaction(self):
        if self.ready == False:
            return
        compactionpending = self.get_attr("org.apache.cassandra.db:type=CompactionManager",
                                          "PendingTasks")
        perf = PERF_FORMAT.format(type="compaction_pending", value=compactionpending,
                                  warning=CASSPENDINGWARN, critical=CASSPENDINGCRIT)
        msg = "Compaction pending tasks"
        return OUTPERF_FORMAT.format(entity="Cassandra:CompactPending", perf=perf, message=msg)	

    def CassMntrCache(self):
        if self.ready == False:
            return
        keycachehits = str(self.get_attr("org.apache.cassandra.db:type=Caches", "KeyCacheHits"))
        keycacherequests = str(self.get_attr("org.apache.cassandra.db:type=Caches",
                                             "KeyCacheRequests"))
        keycachehitrate = float(keycacherequests)/float(keycachehits)
        perf = PERF_FORMAT.format(type="keycache_hitrate", value=keycachehitrate,
                                  warning=CASSKEYCACHEWARN, critical=CASSKEYCACHECRIT)
        msg = "Key Cache hit rate"
        return OUTPERF_FORMAT.format(entity="Cassandra:Cacherate", perf=perf, message=msg)	

    def CassMntrThreadPool(self):
        res = list()

        if self.ready == False:
            return
        #Pending tasks
        aepending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=AntiEntropyStage,name=PendingTasks", "Value")))
        gossippending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=GossipStage,name=PendingTasks", "Value")))
        irpending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=InternalResponseStage,name=PendingTasks", "Value")))
        migpending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=MigrationStage,name=PendingTasks", "Value")))
        miscpending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=MiscStage,name=PendingTasks", "Value")))
        mutpending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=MutationStage,name=PendingTasks", "Value")))
        readpending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=ReadStage,name=PendingTasks", "Value")))
        rowpending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=ReplicateOnWriteStage,name=PendingTasks", "Value")))
        rrspending = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=RequestResponseStage,name=PendingTasks", "Value")))
        totalpending =  aepending + gossippending + irpending + migpending + miscpending + \
                        mutpending + readpending + rowpending + rrspending
        perf = PERF_FORMAT.format(type="TP_Pendingtasks", value=totalpending,
                                  warning=CASSPENDINGWARN, critical=CASSPENDINGCRIT)
        msg = "Thread pool pending tasks"
        res.append(OUTPERF_FORMAT.format(entity="Cassandra:TPPending", perf=perf, message=msg))	

        aeblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=AntiEntropyStage,name=CurrentlyBlockedTasks", "Count")))
        gossipblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=GossipStage,name=CurrentlyBlockedTasks", "Count")))
        irblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=InternalResponseStage,name=CurrentlyBlockedTasks", "Count")))
        migblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=MigrationStage,name=CurrentlyBlockedTasks", "Count")))
        miscblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=internal,scope=MiscStage,name=CurrentlyBlockedTasks", "Count")))
        mutblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=MutationStage,name=CurrentlyBlockedTasks", "Count")))
        readblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=ReadStage,name=CurrentlyBlockedTasks", "Count")))
        rowblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=ReplicateOnWriteStage,name=CurrentlyBlockedTasks", "Count")))
        rrsblocked = int(str(self.get_attr("org.apache.cassandra.metrics:type=ThreadPools,"
                            "path=request,scope=RequestResponseStage,name=CurrentlyBlockedTasks", "Count")))
        totalblocked =  aeblocked + gossipblocked + irblocked + migblocked + miscblocked + \
                        mutblocked + readblocked + rowblocked + rrsblocked
        perf = PERF_FORMAT.format(type="TP_CurrentlyBlockedtasks", value=totalblocked,
                                  warning=CASSPENDINGWARN, critical=CASSPENDINGCRIT)
        msg = "Thread pool blocked tasks"
        res.append(OUTPERF_FORMAT.format(entity="Cassandra:TPBlocked", perf=perf, message=msg))	

        return res

    def CassMntrClusterConnectivity(self):
        if self.ready == False:
            return
        cluster = self.get_attr("org.apache.cassandra.db:type=StorageService",
                                "LiveNodes")
        if (len(cluster) != CASSCLUSTERSIZE):
            misscluster = self.get_attr("org.apache.cassandra.db:type=StorageService",
                                        "UnreachableNodes")
            status = STATUS.get("critical")
            msg = "CRITICAL: "+"Not connected completely. Connected to " + str(cluster) + \
                   "Not able to connect to " + str(misscluster)
            return OUTPUT_FORMAT.format(status=status, entity="Cassandra:Cluster", message=msg)
        else:
            status = STATUS.get("success")
            msg = "OK: "+"All is well. Connected to "+str(cluster)
            return OUTPUT_FORMAT.format(status=status, entity="Cassandra:Cluster", message=msg)


    def CassMntrLatency(self):
        res = list()

        if self.ready == False:
            return
        #Read latency 
        readlatstr = str(self.get_attr("org.apache.cassandra.db:type=ColumnFamilies,keyspace=system,"
                                    "columnfamily=Schema","RecentReadLatencyMicros"))
        if readlatstr == "NaN":
            readlat = 0.0
        else:
            readlat = float(readlatstr)
        perf = PERF_FORMAT.format(type="Read_Latency", value=readlat,
                                  warning=CASSLATWARN, critical=CASSLATCRIT)
        msg = "DB Read latency"
        res.append(OUTPERF_FORMAT.format(entity="Cassandra:RdLat", perf=perf, message=msg))	

        #Write latency 
        writelatstr = str(self.get_attr("org.apache.cassandra.db:type=ColumnFamilies,keyspace=system,"
                                    "columnfamily=Schema","RecentWriteLatencyMicros"))
        if writelatstr == "NaN":
            writelat = 0.0
        else:
            writelat = float(writelatstr)
        perf = PERF_FORMAT.format(type="Write_Latency", value=writelat,
                                  warning=CASSLATWARN, critical=CASSLATCRIT)
        msg = "DB Write latency"
        res.append(OUTPERF_FORMAT.format(entity="Cassandra:WrLat", perf=perf, message=msg))	
        
        return res

class ZkMonitor(object):

    @classmethod
    def process_zkcmd(cls, cmd):
        zkobj = None
        try:
            zkobj = Tel(HOST,ZKPORT)
        except:
            status = STATUS.get("critical")
            msg = "CRITICAL: "+"Unable to connect to client port. Reason : "+ str(ex)
            return FAIL, OUTPUT_FORMAT.format(status=status, entity="Zookeeper:Connection", message=msg)
        return SUCCESS, zkobj.request(cmd)


    @classmethod
    def get_zk_status(cls):
        resp_code, resp = cls.process_zkcmd("ruok")
        if resp_code == FAIL:
            return resp

        if resp == "imok":
            status = STATUS.get("success")
            msg = "OK: "+"Returned ok"
        else:
            status = STATUS.get("critical")
            msg = "CRITICAL: "+"Not keeping well"
        return OUTPUT_FORMAT.format(status=status, entity="Zookeeper:Status", message=msg)

    @classmethod
    def process_zk_cluster_status(cls, stats, lep_stat, lcp_stat):
        res = list()
        lepcount = 0
        lcpcount = 0
        pdest = list()
        ldest = list()

        if "follower" in stats:
            mode = "follower"
        else:
            mode = "leader"

        lep_lines = lep_stat.split("\n")
        for line in lep_lines:
            if "ESTABLISHED" in line:
                lepcount = lepcount + 1
                words = line.split()
                destword = words[4]
                dest = destword.split(":")[0]
                pdest.append(dest)

        lcp_lines = lcp_stat.split("\n")
        for line in lcp_lines:
            if "ESTABLISHED" in line:
                lcpcount = lcpcount + 1
                words = line.split()
                destword = words[4]
                dest = destword.split(":")[0]
                ldest.append(dest)

        if lepcount == 2:
            status = STATUS.get("success")
            msg = "OK: Connected to two peers " + str(pdest)
        else:
            status = STATUS.get("critical")
            msg = "CRITICAL: Connected to "+str(lepcount)+" peer(s). Peer list : "+str(pdest)
        res.append(OUTPUT_FORMAT.format(status=status, entity="Zookeeper:ClusterPeers", message=msg))
            
        if mode == "follower":
            if lcpcount == 1:
                status = STATUS.get("success")
                msg = "OK: Connected to leader as follower"
            else:
                status = STATUS.get("critical")
                msg = "CRITICAL: Not connected to leader"
        else:
            if lcpcount == 2:
                status = STATUS.get("success")
                msg = "OK: Connected to two followers as leader"
            else:
                status = STATUS.get("critical")
                msg = "CRITICAL: Connected to "+str(lepcount)+" follower(s). Follower list : "+str(ldest)
        res.append(OUTPUT_FORMAT.format(status=status, entity="Zookeeper:ClusterConn", message=msg))

        return res

    @classmethod
    def process_zk_stats(cls, stats):
        res = list()
        statlines = stats.split("\n")
        for line in statlines:
            if "zk_avg_latency" in line:
                words = line.split()
                avg_latency = int(words[1])
                perf = PERF_FORMAT.format(type="avg_latency", value=avg_latency, warning=ZKWARNLAT, critical=ZKCRITLAT)
                msg = "Average latency in this period"
                res.append(OUTPERF_FORMAT.format(entity="Zookeeper:AvgLat", perf=perf, message=msg))	

            elif "zk_max_latency" in line:
                words = line.split()
                max_latency = int(words[1])
                perf = PERF_FORMAT.format(type="max_latency", value=max_latency, warning=ZKWARNLAT, critical=ZKCRITLAT)
                msg = "Max latency in this period"
                res.append(OUTPERF_FORMAT.format(entity="Zookeeper:MaxLat", perf=perf, message=msg))	

            elif "zk_outstanding_requests" in line:
                words = line.split()
                pending_reqs = int(words[1])
                perf = PERF_FORMAT.format(type="pending_reqs", value=pending_reqs, warning=ZKWARNREQ, critical=ZKCRITREQ)
                msg = "Outstanding requests"
                res.append(OUTPERF_FORMAT.format(entity="Zookeeper:OutstandingReqs", perf=perf, message=msg))	
        return res

    @classmethod
    def check_zk_stats(cls):
        resp_code, resp = cls.process_zkcmd("mntr")
        if resp_code == FAIL:
            return resp
        cls.process_zkcmd("srst")
        return cls.process_zk_stats(resp)	

    @classmethod
    def check_zk_cluster_status(cls):
        resp_code, resp = cls.process_zkcmd("srvr")
        if resp_code == FAIL:
            return resp
        lep_status = Netstat.tcp_check(ZKLDRELPRT)
        lcp_status = Netstat.tcp_check(ZKLDRCONPRT)
        return cls.process_zk_cluster_status(resp, lep_status, lcp_status)


if __name__ == "__main__":
    CassMntr = CassMonitor()
    pipe = [ZkMonitor.get_zk_status,
	        ZkMonitor.check_zk_stats,
            ZkMonitor.check_zk_cluster_status,
            CassMntr.CassMntrGc,
            CassMntr.CassMntrCompaction,
            CassMntr.CassMntrCache,
            CassMntr.CassMntrThreadPool,
            CassMntr.CassMntrLatency,
            CassMntr.CassMntrClusterConnectivity]

    for fun in pipe:
	res = None
	try:
	    res = fun()
	except:
	    print OUTPUT_FORMAT.format(status=STATUS.get("critical"), entity="Monitoring Script:{script}".format(script=fun.__name__),
		message="CRITICAL: Monitoring script failed")

	if res:
	    if isinstance(res, list):
		for r in res:
		    print r
	    else:
		print res
	    
