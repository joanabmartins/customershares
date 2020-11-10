##Parameters

$subscriptionId = ""

$vmName= ""
$cloudService = ""

##Login to Azure

Add-AzureAccount

Select-AzureSubscription –SubscriptionId $subscriptionId

Connect-AzAccount -SubscriptionId $subscriptionId


#Get VM and disk Details
$OriginalVM = Get-AzureVM -ServiceName $cloudService -Name $vmName
$OSDisk = Get-AzureOSDisk -VM $OriginalVM
$DataDisk = Get-AzureDataDisk -VM $OriginalVM



#Output VM details to file 
$outFile = "C:\temp\” + $vmName + “.txt"

$OriginalVM | Out-File -FilePath $outFile

"OS Disk(): " | Out-File -FilePath $outFile -Append
$OSDisk | Out-File -FilePath $outFile -Append

if ($DataDisk) {
    "Data Disk(s): " | Out-File -FilePath $outFile -Append
    $DataDisk | Out-File -FilePath $outFile -Append
}




#####################################################
#Remove the original VM

Remove-AzureVM -Name $vmName -ServiceName $cloudService

##############################################################
######Redeployment
#############################################################


$nicName= ""
$rgName= ""
$location = "westeurope"
$osDiskUri = $OSDisk.MediaLink


#Get Nic
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName

#Create the basic configuration for the replacement VM
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $OriginalVM.InstanceSize 
$vm = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

$osDiskName = $vmName + "osDisk"
$vm = Set-AzVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Windows



#Add Data Disks
$i=1
foreach ($disk in $DataDisk ) { 
    $dataDiskName = $vmName + "dataDisk" + $i 
    $dataDiskUri = $disk.MediaLink
$vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -VhdUri $dataDiskUri -Lun $i -CreateOption attach
$i=$i+1
    }


#Create the VM
New-AzVM -ResourceGroupName $rgName -Location $location -VM $vm



