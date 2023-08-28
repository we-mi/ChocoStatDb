---
external help file: ChocoStatDb-help.xml
Module Name: ChocoStatDb
online version: https://github.com/we-mi/ChocoStatDb/blob/main/docs/Get-ChocoStatComputer.md
schema: 2.0.0
---

# Get-ChocoStatComputer

## SYNOPSIS
Lists computers in the ChocoStat-Database

## SYNTAX

### ComputerName (Default)
```
Get-ChocoStatComputer [-ComputerName <String[]>] [-Packages] [-FailedPackages] [-Sources]
 [-Database <FileInfo>] [<CommonParameters>]
```

### ComputerID
```
Get-ChocoStatComputer [-ComputerID <Int32[]>] [-Packages] [-FailedPackages] [-Sources] [-Database <FileInfo>]
 [<CommonParameters>]
```

## DESCRIPTION
Lists computers in the ChocoStat-Database depending on the filters.
You can include packages, failed packages and sources which are attached to this computer

## EXAMPLES

### EXAMPLE 1
```
Get-ChocoStatComputer
```

Lists all computers in the database

### EXAMPLE 2
```
Get-ChocoStatComputer -ComputerID 5
```

Lists only the computer with the ID "5"

### EXAMPLE 3
```
Get-ChocoStatComputer -ComputerID 5,7
```

Lists only the computers with the ID "5" and "7"

### EXAMPLE 4
```
Get-ChocoStatComputer -ComputerName '%.example.org'
```

Lists all computers which ends with \`.example.org\`

### EXAMPLE 5
```
Get-ChocoStatComputer -ComputerName '%.example.org','%foo%'
```

Lists all computers which ends with \`.example.org\` or which contains the word \`foo\`

### EXAMPLE 6
```
Get-ChocoStatComputer -ComputerName '%.example.org' -Packages -FailedPackages -Sources
```

Lists all computers which ends with \`.example.org\` and also shows attached packages, failed packages and sources for these computers

## PARAMETERS

### -ComputerID
One or more ComputerIDs to search for

```yaml
Type: Int32[]
Parameter Sets: ComputerID
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
One or more ComputerNames to search for (can contain SQL wildcards)

```yaml
Type: String[]
Parameter Sets: ComputerName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Packages
Should the search include package information for computers?

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FailedPackages
Should the search include failed package information for computers?

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sources
Should the search include source information for computers?

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Database
Path to the SQLite-Database.
Leave empty to let \`Get-ChocoStatDBFile\` search for it automatically

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Object[]
## NOTES
The output can be filtered by one or more ComputerIDs *OR* one or more ComputerNames which might contain SQL-Wildcards

## RELATED LINKS

[https://github.com/we-mi/ChocoStatDb/blob/main/docs/Get-ChocoStatComputer.md](https://github.com/we-mi/ChocoStatDb/blob/main/docs/Get-ChocoStatComputer.md)

