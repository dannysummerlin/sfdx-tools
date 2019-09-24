ipmo .\sfdx-cmdlets.ps1 -force
$mongoURI = "mongodb://$(gc 'mongo.key')" # make this secure

if(!(Get-Module -ListAvailable -Name mdbc)) {
	# Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
	install-module mdbc
}

$objects = New-Object System.Collections.ArrayList
foreach($objectName in $(gc sObjects.list)) {
	$null = $objects.Add(@{ name = $objectName; where = "" })
}
$limit = 2000

foreach($o in $objects) {
	echo "Processing $($o.name)"
	$mongo = Connect-MDBC -ConnectionString $mongoURI -DatabaseName "salesforce_snapshots" -CollectionName $o.name
	$fields = @(Get-SFDXObjectEditableFieldNames -object $o.name) -join ", "
	$firstRun = $true
	$lastId = ""
	$results = ""
	try {
		while($firstRun -or $results.count -gt 0) {
			if($firstRun) { $firstRun = $false }
			# $results = Get-SFDXQuery -soql "select Id, $fields from $($o.name) where $($o.where) Id > '$lastId' and LastModifiedDate > LAST_N_FISCAL_YEARS:3 ORDER BY Id LIMIT $limit"
			$results = Get-SFDXQuery -soql "select Id, $fields from $($o.name) where $($o.where) Id > '$lastId' and LastModifiedDate > YESTERDAY ORDER BY Id LIMIT $limit"
			if($results.count -gt 0) {
				echo "backing up $($results.count) records"
				foreach($r in $results) { $r | Add-Member -MemberType NoteProperty -Name _dateImported -Value (Date) }
				$results | Add-MDBCData
				$lastId = $results[$results.count - 1].Id
			}
		}
	} catch {
		# issue with query
		echo $_.Exception.Message
	}
}
