$env:path = $env:path + ";c:\Program Files\Salesforce CLI\bin"

#
# Gets (need to update help)
#
function Get-SFDXHelp {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $command,
	[switch] $org,
	[switch] $alias,
	[switch] $apex,
	[switch] $auth,
	[switch] $config,
	[switch] $data,
	[switch] $doc,
	[switch] $lightning,
	[switch] $limits,
	[switch] $mdapi,
	[switch] $package,
	[switch] $package1,
	[switch] $project,
	[switch] $schema,
	[switch] $source,
	[switch] $user,
	[switch] $visualforce
)
	Begin {
		$scope = ""
		# if($force) $command = "force:" + $command
		if($org) { $scope = "force:org" }
		if($alias) { $scope = "force:alias" }
		if($apex) { $scope = "force:apex" }
		if($auth) { $scope = "force:auth" }
		if($config) { $scope = "force:config" }
		if($data) { $scope = "force:data" }
		if($doc) { $scope = "force:doc" }
		if($lightning) { $scope = "force:lightning" }
		if($limits) { $scope = "force:limits" }
		if($mdapi) { $scope = "force:mdapi" }
		if($package) { $scope = "force:package" }
		if($package1) { $scope = "force:package1" }
		if($project) { $scope = "force:project" }
		if($schema) { $scope = "force:schema" }
		if($source) { $scope = "force:source" }
		if($user) { $scope = "force:user" }
		if($visualforce) { $scope = "force:visualforce" }
		$command = $scope + ":" + $command
		$command = $command.Replace("::",":") -Replace ":$",""
	}
	Process {
		$output = @(sfdx help $command)
#		$output = $output -Replace "\$ sfdx $($scope):", ("$ Get-SFDX" + ($scope -replace ":","-") + "-")
	}
	End { return $output }
}

function Get-SFDXOrgs {
[cmdletbinding()]
param()
	Begin { $outputOrgs = New-Object System.Collections.ArrayList }
	Process {
		$orgList = @(sfdx force:org:list).split("`n")
		$fields = [regex]::split($orgList[1],"\s\s+")
		for($i = 3; $orgList[$i] -ne ""; $i++) {
			$row = [regex]::split($orgList[$i],"\s\s+")
			$output = @{}
			for($j = 1; $j -lt $row.length; $j++) {
				$output[ $fields[$j] ] = $row[$j]
			}
			$outputOrgs.Add($output) > $null
		}
	}
	End { return $outputOrgs }
}

function Get-SFDXQuery {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $soql,
	[string] $userName
)
	Begin { $outputRecords = New-Object System.Collections.ArrayList }
	Process {
		try {
			$queryOutput = Get-SFDXQueryRaw -soql "$soql" -userName $userName | ConvertFrom-Json
			if($queryOutput.message -ne $null) {
				write-error $queryOutput.message
			} else { $outputRecords = $queryOutput.result.records }
		} catch {
			write-error $_.Exception.message
		}
	}
	End { return $outputRecords }
}

function Get-SFDXQueryRaw {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $soql,
	[string] $userName
)
	Begin { $queryOutput = "" }
	Process {
		try {
			if($userName -ne '') {
				$queryOutput = $(sfdx force:data:soql:query -q "$soql" -u $userName --json)
			} else {
				$queryOutput = $(sfdx force:data:soql:query -q "$soql" --json)
			}
		} catch {
			write-error $_.Exception.message
		}
	}
	End { return $queryOutput }
}

function Get-SFDXObjectFields {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $object,
	[string] $userName
)
	Begin { $outputFields = New-Object System.Collections.ArrayList }
	Process {
		try {
			if($userName -ne '') {
				$queryOutput = $(sfdx force:schema:sobject:describe -s "$object" -u $userName --json) | ConvertFrom-Json
				# $queryOutput = $jsonSerializer.DeserializeObject($(sfdx force:schema:sobject:describe -s "$object" -u $userName --json))
			}
			else {
				$queryOutput = $(sfdx force:schema:sobject:describe -s "$object" --json) | ConvertFrom-Json
				# $queryOutput = $jsonSerializer.DeserializeObject($(sfdx force:schema:sobject:describe -s "$object" --json))
			}
			if($queryOutput.message -ne $null) { write-error $queryOutput.message }
			else { $outputFields = $queryOutput.result.fields }
		} catch { write-error $_.Exception.message }
	}
	End { return $outputFields }
}

function Get-SFDXObjectEditableFields {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $object,
	[string] $userName
)
	Begin { $outputFields = New-Object System.Collections.ArrayList }
	Process {
		$fields = Get-SFDXObjectFields -object $object -userName $userName
		try { $outputFields =  $fields | where {$_.updateable -eq $true} }
		catch { write-error $_.Exception.message }
	}
	End { return $outputFields }
}

function Get-SFDXObjectEditableFieldNames {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $object,
	[string] $userName
)
	Begin { $outputFields = New-Object System.Collections.ArrayList }
	Process {
		try {
			$fields = Get-SFDXObjectEditableFields -object $object -userName $userName
			for($i = 0; $i -lt $fields.count; $i++) {
				$quiet = $outputFields.Add($fields[$i].name)
			}
		} catch {
			echo $_.Exception.message
			# error handling here
		}
	}
	End { return $outputFields }
}

function Get-SFDXAllGroups {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $soql,
	[string] $userName
)
	Begin { $outputRecords = New-Object System.Collections.ArrayList }
	Process {
		try {
			$queryOutput = Get-SFDXQuery -soql "SELECT id,name FROM group where name not in (null,'',' ')" -userName $userName
			if($queryOutput.message -ne $null) {
				write-error $queryOutput.message
			} else {
				$outputRecords = $queryOutput.result.records
			}
		}
		catch { write-error $_.Exception.message }
	}
	End { return $outputRecords }
}

function Get-SFDXGroup {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $groupName,
	[string] $userName
)
	Begin { $outputRecord = @{} }
	Process {
		try {
			if($groupName -ne '') {
				$queryOutput = Get-SFDXQuery -soql "SELECT id,name FROM group where name = '$groupName'" -userName $userName
			}
			else { write-error "You must include a group name to get" }

			if($queryOutput.message -ne $null) { write-error $queryOutput.message }
			elseif ($queryOutput.id -eq $null) { write-error "No groups called '$groupName' found" }
			else { $outputRecord = $queryOutput }
		}
		catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}

function Get-SFDXUser {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $email,
	[string] $id,
	[string] $alias,
	[string] $contactId,
	[string] $leadId,
	[string] $userName
)
	Begin {
		$outputRecord = @{}
		$whereClause = New-Object System.Collections.ArrayList
	}
	Process {
		try {
			if($email) { $whereClause.Add("email = '$email'") }
			if($id) { $whereClause.Add("id = '$id'") }
			if($alias) { $whereClause.Add("alias = '$alias'") }
			if($contactId) { $whereClause.Add("JS_Contact_ID__c = '$contactId'") }
			if($leadId) { $whereClause.Add("JS_Lead_ID__c = '$leadId'") }
			if($whereClause.count -gt 0) {
				$queryOutput = Get-SFDXQuery -soql "SELECT id,name FROM User where $($whereClause -join ' and ')" -userName $userName
			} else { write-error "You must include an email, alias, Contact ID, or Lead ID to find a user" }

			if($queryOutput.message -ne $null) { write-error $queryOutput.message }
			elseif ($queryOutput.id -eq $null) { write-error "No users matching '$($whereClause -join ' and ')' found" }
			else { $outputRecord = $queryOutput }
		}
		catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}

#
# Adding data
#

function Add-SFDXRecord {
[cmdletbinding()]
param(
	[parameter(Mandatory = $true, ValueFromPipeline = $true)] $values,
	[parameter(Mandatory = $true)][String] $sObject,
	[String] $userName
)
	Begin { $outputRecord = @{} }
	Process {
		try {
			if($values.getType().name -ne 'String') {
				$valuesJoin = New-Object System.Collections.ArrayList
				$values.keys | %{ $valuesJoin.Add("$_='$($values[$_])'") }
				$valueString = $valuesJoin -join " "
			} else { $valueString = $values }
			if($userName -ne '') {
				$addResult = $(sfdx force:data:record:create -s "$sObject" -v "$valueString" -u $userName --json) | ConvertFrom-Json
			}
			else {
				$addResult = $(sfdx force:data:record:create -s "$sObject" -v "$valueString" --json) | ConvertFrom-Json
			}

			if($addResult.message -ne $null) { write-error ($addResult.message | ConvertFrom-Json) }
			else {
				if($values.getType().name -ne 'String') {
					$values.id = $addResult.result.id
					$outputRecord = $values
				}
				else {
					$outputRecord = @{id = $addResult.result.id }
					# need to chop up values into properties ideally
				}
			}
		} catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}

function Add-SFDXGroup {
[cmdletbinding()]
param(
	[parameter(ValueFromPipeline = $true)] $groupName,
	[string] $userName
)
	Begin { $outputRecord = @{} }
	Process {
		try {
			if($groupName -ne '') {
				$queryOutput = Add-SFDXRecord -sObject Group -v @{ Name = $groupName } -userName $userName
			}
			else { write-error "You must include a group name to add" }

			if($queryOutput.message -ne $null) { write-error $queryOutput.message }
			elseif ($queryOutput.id -eq $null) { write-error "Could not create '$groupName'" }
			else { $outputRecord = $queryOutput }
		}
		catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}

function Add-SFDXGroupMembers {
[cmdletbinding()]
param(
	[parameter(Mandatory = $true, ValueFromPipeline = $true)] $memberEmails,
	[parameter(Mandatory = $true)][string] $groupName,
	[string] $userName
)
	Begin { $outputRecord = @{} }
	Process {
		try {
			if($groupName -ne '') {
				$group = Get-SFDXGroup -groupName $groupName
				if($memberEmails.getType().name -eq 'String') { $memberEmails = @($memberEmails) }
				if ($memberEmails -eq "" -or $memberEmails -eq $null) {
				    write-error "You must include members to add to the group"
				} else {
					foreach($u in $memberEmails) {
						$user = Get-SFDXUser -email $u
						if($group.Id -ne $null -and $user.Id -ne $null) {
							$queryOutput = Add-SFDXRecord -sObject GroupMember -v @{ GroupId = $group.Id; UserOrGroupId = $user.Id } -userName $userName
						}
					}
				}
			}
			else { write-error "You must include a group name to add" }

			if($queryOutput.message -ne $null) { write-error $queryOutput.message }
			elseif ($queryOutput.id -eq $null) { write-error "Could not add members to '$groupName'" }
			else { $outputRecord = $queryOutput }
		}
		catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}

#
#
#
function Remove-SFDXRecord {
[cmdletbinding()]
param(
	[parameter(Mandatory = $true, ValueFromPipeline = $true)] $recordId,
	[parameter(Mandatory = $true)][String] $sObject,
	[switch] $confirm,
	[String] $userName
)
	Begin { $outputRecord = @{} }
	Process {
		try {
			if($confirm -and $recordId) {
				if($userName -ne '') {
					$removeResult = $(sfdx force:data:record:delete -s "$sObject" -i "$recordId" -u $userName --json) | ConvertFrom-Json
				}
				else {
					$removeResult = $(sfdx force:data:record:delete -s "$sObject" -i "$recordId" --json) | ConvertFrom-Json
				}
				if($removeResult.message -ne $null) { write-error ($removeResult.message | ConvertFrom-Json) }
				else {
					$outputRecord = $removeResult.result
				}
			}
		} catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}


function Remove-SFDXGroupMembers {
[cmdletbinding()]
param(
	[parameter(Mandatory = $true, ValueFromPipeline = $true)] $memberEmails,
	[parameter(Mandatory = $true)][string] $groupName,
	[string] $userName
)
	Begin { $outputRecord = @{} }
	Process {
		try {
			if($groupName -ne '') {
				$group = Get-SFDXGroup -groupName $groupName
				if($memberEmails.getType().name -eq 'String') { $memberEmails = @($memberEmails) }
				if ($memberEmails -eq "" -or $memberEmails -eq $null) {
				    write-error "You must include members to add to the group"
				} else {
					foreach($e in $memberEmails) {
						$user = Get-SFDXUser -email $e
						if($group.Id -ne $null -and $user.Id -ne $null) {
							$membershipRecord = Get-SFDXQuery -soql "SELECT Id FROM GroupMember where UserOrGroupId = '$($user.id)' and GroupId = '$($group.Id)'"
							if($membershipRecord) {
								$queryOutput = Remove-SFDXRecord -sObject GroupMember -recordId $membershipRecord.Id -userName $userName -confirm
							}
						}
					}
				}
			}
			else { write-error "You must include a group name to add" }

			if($queryOutput.message -ne $null) { write-error $queryOutput.message }
			else { $outputRecord = $queryOutput }
		}
		catch { write-error $_.Exception.message }
	}
	End { return $outputRecord }
}
