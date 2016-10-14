$AccountName = '<acc>'
$Key = '<DDBKey>'
$Database = '<db>'
$Collection = '<coll>'

$csv = import-csv '<path to file>.csv'

foreach($row in $csv)
    {
    $row| Add-Member -MemberType NoteProperty -Name id -Value $(new-guid).guid
    
    Set-DocDBDocument -DBName $Database -accountName $AccountName -key $key -collection $Collection -PSdocument $row|out-null
    }
