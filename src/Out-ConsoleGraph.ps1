<#
    .SYNOPSIS
        Draws a bar graph for the specified property of an object.

    .DESCRIPTION
        Takes in an object and draws a bar graph for the specified property of the object.
    
    .PARAMETER InputObject
        The object which contains the property which should be graphed. This accepts objects from the pipeline.
    
    .PARAMETER GraphProperty
        The name of the property to graph.
    
    .PARAMETER Property
        Any other properties which should be displayed along with the graph.
    
    .EXAMPLE
        Get-ChildItem -Path $env:SystemRoot -File | Out-ConsoleGraph -GraphProperty Length -Property Name,CreationTime,Length
    
    .EXAMPLE
        Get-Process | Out-ConsoleGraph -GraphProperty CPU -Property ProcessName,CPU
    
    .NOTES
        Credit:
            Jeffery Hicks
            https://powershell.org/2013/01/09/graphing-with-the-powershell-console/
#>
function Out-ConsoleGraph
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $True
        )]
        [System.Object]
        $InputObject,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter a property name to graph'
        )]
        [ValidateNotNullorEmpty()]
        [System.String]
        $GraphProperty,

        [Parameter()]
        [ValidateNotNullorEmpty()]
        [System.String[]]
        $Property
    )

    Begin
    {
        # Get the current window width so that our lines will be proportional
        $width = $Host.UI.RawUI.BufferSize.Width
    
        # Initialize an array to hold the data
        $data = @()
    }

    Process
    {
        # Cache the data in order to work with all of it
        $data += $Inputobject
    }

    End
    {
        # Ensure the property exists on the object
        if ( -not ( $data | Get-Member -Name $GraphProperty ) )
        {
            throw "Failed to find property '$GraphProperty'"
        }
        
        # Get the largest value from the supplied property to graph
        $largestValue = $data | Sort-Object -Property $GraphProperty -Descending | Select-Object -ExpandProperty $GraphProperty -First 1
        
        # Define the total length of the columns used by the other properties
        $totalLength = 0

        if ( $PSBoundParameters.ContainsKey('Property') )
        {
            foreach ( $objectProperty in $Property )
            {
                $currentLength = $data | Select-Object -ExpandProperty $objectProperty -ErrorAction SilentlyContinue | ForEach-Object -Process { $_.ToString().Length } | Sort-Object -Descending | Select-Object -First 1
                $totalLength = $totalLength + $currentLength
            }

            # Add extra space for each property passed
            $totalLength = $totalLength + ( $Property.Count * 1 )
        }

        # Get the remaining available window width, dividing by 100 to get a proportional width. Subtract 4 to add a little margin.
        $available = ( $width - $totalLength - 4 ) / 100

        foreach ($obj in $data)
        {
            # If the property is zero, null or empty, or doesn't exist on the object
            if ( ( $obj.$GraphProperty -eq 0 ) -or [System.String]::IsNullOrEmpty($obj.$GraphProperty) -or ( -not ( $obj | Get-Member -Name $GraphProperty ) ) )
            {
                # Don't display anything on the graph
                $graph = 0
            }
            else
            {
                # Calculate the length of the graph
                [System.Decimal]$graph = (($obj.$GraphProperty) / $largestValue) * 100 * $available
            }

            # Determine which graph character to use
            if ( $graph -ge 1 )
            {
                # Specify the full block character
                [System.String]$g = [System.Char]9608

                # Create a string of block characters
                $graphPrint = $g * $graph
            }
            elseif ( $graph -gt 0 -AND $graph -lt 1 )
            {
                # Use the half block character
                [System.String]$graphPrint = [System.Char]9612
            }

            # Create an array of properties which should be selected
            $selectProperties = @()

            # Add the supplied properties to the select array
            if ( $PSBoundParameters.ContainsKey('Property') )
            {
                $selectProperties += $Property
            }

            # Add the graph as the last property
            $selectProperties += @{n="$($GraphProperty)Graph";e={$graphPrint}}

            # Finally, return the selected properties with the graph
            $obj | Select-Object -Property $selectProperties
        }
    }
}
