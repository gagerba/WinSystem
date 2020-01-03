#Source: http://www.checkyourlogs.net/?p=37573

#Role Installation
Install-WindowsFeature -Name File-Services
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart
Invoke-Command -Computername SVR-S2D-02 -ScriptBlock {
Install-WindowsFeature -Name File-Services
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart
}
Invoke-Command -Computername SVR-S2D-03 -ScriptBlock {
Install-WindowsFeature -Name File-Services
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart
}
 
#Reboot Nodes
Invoke-Command -Computername SVR-S2D-02 -ScriptBlock {Restart-Computer -Force}
Invoke-Command -Computername SVR-S2D-03 -ScriptBlock {Restart-Computer -Force}
Restart-Computer -Force
 
#Build NIC Team
New-NetlbfoTeam PRODVLAN "Ethernet", "Ethernet 3" -TeamingMode LACP –verbose
 
#Get the Status of the Network Adapters
Get-NetAdapter | Sort Name
 
#Create the new Hyper-V Vswitch VSW01
new-vmswitch "VSW01" -MinimumBandwidthMode Weight -NetAdapterName "PRODVLAN" -verbose
 
#Check the Bindings
Get-NetadapterBinding | where {$_.DisplayName –like "Hyper-V*"}
 
#Check the Adapter Settings
Get-NetAdapter | sort name
 
#Create the Converged Adapters
Add-VMNetworkAdapter –ManagementOS –Name "LM" –SwitchName "VSW01" –verbose
Add-VMNetworkAdapter –ManagementOS –Name "HB" –SwitchName "VSW01" –verbose
Add-VMNetworkAdapter –ManagementOS –Name "CLUSTERCSV" –SwitchName "VSW01" –verbose
 
#Review the NIC Configuration Again
Get-NetAdapter | Sort name
 
#Rename the HOST NIC
Rename-NetAdapter –Name "vEthernet (VSW01)" –NewName "vEthernet (Host)" –verbose
 
#Review the NIC Configuration Again
Get-NetAdapter | Sort name
 
#Set the weighting on the NIC's
Set-VMNetworkAdapter –ManagementOS –Name "CLUSTERCSV" –MinimumBandwidthWeight 40
Set-VMNetworkAdapter –ManagementOS –Name "LM" –MinimumBandwidthWeight 30
Set-VMNetworkAdapter –ManagementOS –Name "HB" –MinimumBandwidthWeight 20
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "HB" -Access -VLanID 257
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "LM" -Access -VLanID 258
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CLUSTERCSV" -Access -VLanID 259
 
Invoke-Command -Computername SVR-S2D-02 -ScriptBlock {
New-NetlbfoTeam PRODVLAN "Ethernet 3", "Ethernet 4" -TeamingMode LACP –verbose
new-vmswitch "VSW01" -MinimumBandwidthMode Weight -NetAdapterName "PRODVLAN" -verbose
Add-VMNetworkAdapter –ManagementOS –Name "LM" –SwitchName "VSW01" –verbose
Add-VMNetworkAdapter –ManagementOS –Name "HB" –SwitchName "VSW01" –verbose
Add-VMNetworkAdapter –ManagementOS –Name "CLUSTERCSV" –SwitchName "VSW01" –verbose
Rename-NetAdapter –Name "vEthernet (VSW01)" –NewName "vEthernet (Host)" –verbose
Set-VMNetworkAdapter –ManagementOS –Name "CLUSTERCSV" –MinimumBandwidthWeight 40
Set-VMNetworkAdapter –ManagementOS –Name "LM" –MinimumBandwidthWeight 30
Set-VMNetworkAdapter –ManagementOS –Name "HB" –MinimumBandwidthWeight 20
Set-VMNetworkAdapter –ManagementOS –Name "VSW01" –MinimumBandwidthWeight 10
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "HB" -Access -VLanID 257
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "LM" -Access -VLanID 258
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CLUSTERCSV" -Access -VLanID 259
}
 
Invoke-Command -Computername SVR-S2D-03 -ScriptBlock {
New-NetlbfoTeam PRODVLAN "Ethernet", "Ethernet 2" -TeamingMode LACP –verbose
new-vmswitch "VSW01" -MinimumBandwidthMode Weight -NetAdapterName "PRODVLAN" -verbose
Add-VMNetworkAdapter –ManagementOS –Name "LM" –SwitchName "VSW01" –verbose
Add-VMNetworkAdapter –ManagementOS –Name "HB" –SwitchName "VSW01" –verbose
Add-VMNetworkAdapter –ManagementOS –Name "CLUSTERCSV" –SwitchName "VSW01" –verbose
Rename-NetAdapter –Name "vEthernet (VSW01)" –NewName "vEthernet (Host)" –verbose
Set-VMNetworkAdapter –ManagementOS –Name "CLUSTERCSV" –MinimumBandwidthWeight 40
Set-VMNetworkAdapter –ManagementOS –Name "LM" –MinimumBandwidthWeight 30
Set-VMNetworkAdapter –ManagementOS –Name "HB" –MinimumBandwidthWeight 20
Set-VMNetworkAdapter –ManagementOS –Name "VSW01" –MinimumBandwidthWeight 10
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "HB" -Access -VLanID 257
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "LM" -Access -VLanID 258
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CLUSTERCSV" -Access -VLanID 259
}
 
#Configure IPs for Converged Network
New-NetIPAddress -IPAddress 10.10.1.120 -PrefixLength 18 -InterfaceAlias "vEthernet (Host)" -DefaultGateway 10.10.1.1
Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Host)" -ServerAddresses 10.10.1.2,10.10.1.1
New-NetIPAddress -IPAddress 10.10.1.130 -PrefixLength 18 -InterfaceAlias "vEthernet (HB)"
New-NetIPAddress -IPAddress 10.11.1.140 -PrefixLength 18 -InterfaceAlias "vEthernet (LM)"
New-NetIPAddress -IPAddress 172.16.11.10 -PrefixLength 24 -InterfaceAlias "vEthernet (CLUSTERCSV)"
 
Invoke-Command -Computername SVR-S2D-02 -ScriptBlock {
New-NetIPAddress -IPAddress 10.10.1.121 -PrefixLength 18 -InterfaceAlias "vEthernet (Host)" -DefaultGateway 10.10.1.1
Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Host)" -ServerAddresses 10.10.1.2,10.10.1.1
New-NetIPAddress -IPAddress 10.10.1.131 -PrefixLength 18 -InterfaceAlias "vEthernet (HB)"
New-NetIPAddress -IPAddress 10.10.1.141 -PrefixLength 18 -InterfaceAlias "vEthernet (LM)"
New-NetIPAddress -IPAddress 172.16.11.11 -PrefixLength 24 -InterfaceAlias "vEthernet (CLUSTERCSV)"
}
 
Invoke-Command -Computername SVR-S2D-03 -ScriptBlock {
New-NetIPAddress -IPAddress 10.10.1.122 -PrefixLength 18 -InterfaceAlias "vEthernet (Host)" -DefaultGateway 10.10.1.1
Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Host)" -ServerAddresses 10.10.1.2,10.10.1.1
New-NetIPAddress -IPAddress 10.10.1.132 -PrefixLength 18 -InterfaceAlias "vEthernet (HB)"
New-NetIPAddress -IPAddress 10.10.1.142 -PrefixLength 18 -InterfaceAlias "vEthernet (LM)"
New-NetIPAddress -IPAddress 172.16.11.12 -PrefixLength 24 -InterfaceAlias "vEthernet (CLUSTERCSV)"
}
 
#Get Status of NICs
Get-NetAdapter | Sort Name
Invoke-Command -Computername SVR-S2D-02 -ScriptBlock {Get-NetAdapter | Sort Name}
Invoke-Command -Computername SVR-S2D-03 -ScriptBlock {Get-NetAdapter | Sort Name}
 
#Build Cluster
Test-Cluster -Node SVR-S2D-01,SVR-S2D-02,SVR-S2D-03 -Include "Storage Spaces Direct", "Inventory", "System Configuration", "Network"
New-Cluster -Name S2DCluster -Node SVR-S2D-01,SVR-S2D-02,SVR-S2D-03 -NoStorage -StaticAddress 10.10.1.119
 
#Configure Cluster Cloud Witness
Set-ClusterQuorum -CloudWitness -AccountName s2dwitnessazurestorageaccountnotsharedwithotherservices -AccessKey CrAzYLoNgAlPhAnUmErIcEnCrYpTiOnKeY -Endpoint core.windows.net
 
#Validate cluster for S2D
Get-StorageSubsystem
 
#Make sure that all data drives show OperationalStatus=OK
Get-PhysicalDisk | ft
 
#Make sure that all data drives show CanPool=True, OperationalStatus=True
Invoke-Command -Computername SVR-S2D-02 -ScriptBlock {
Get-StorageSubsystem
Get-PhysicalDisk | ft
}
 
#Enable S2D
Enable-ClusterS2D -PoolFriendlyName S2DPool -Confirm:$false
 
#Provision Cluster Shared Volumes
New-Volume -StoragePoolFriendlyName S2DPool -FriendlyName MirrorDisk1 -FileSystem CSVFS_REFS -Size 500GB -PhysicalDiskRedundancy 2 
