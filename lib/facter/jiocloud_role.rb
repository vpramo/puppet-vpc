#
# fact that determines the role based on hostname
#
Facter.add(:jiocloud_role) do
  setcode do
    Facter.value(:hostname).gsub(/^(.*)(\d+).*/, '\1')
  end
end
