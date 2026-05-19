param(

    [string]$CurrentArchitecturePath =
        ".\architecture\current-architecture.json",

    [string]$PreviousArchitecturePath =
        ".\architecture\previous-architecture.json",

    [string]$DiffPath =
        ".\architecture\architecture-diff.json",

    [string]$RuntimeDirectory =
        ".\runtime"
)

function Get-RuntimeTopology {

    param($Directory)

    $runtimeFiles =
        Get-ChildItem `
            -Path $Directory `
            -Filter "*.ps1" `
            -File

    $topology = @()

    foreach ($file in $runtimeFiles) {

        $topology += @{

            runtime_name = $file.Name
            full_path = $file.FullName

            last_modified =
                $file.LastWriteTime.ToString("o")

            size_kb =
                [math]::Round(
                    ($file.Length / 1KB),
                    2
                )
        }
    }

    return @{

        generated_at =
            (Get-Date).ToString("o")

        runtime_count =
            $topology.Count

        runtimes =
            $topology
    }
}

function Save-JsonState {

    param(
        $Object,
        $Path
    )

    $Object |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path
}

function Get-JsonState {

    param($Path)

    if (!(Test-Path $Path)) {
        return @{}
    }

    try {

        $raw =
            Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @{}
        }

        return $raw |
            ConvertFrom-Json -AsHashtable
    }
    catch {

        return @{}
    }
}

function Compare-Architectures {

    param(
        $Current,
        $Previous
    )

    $currentNames =
        $Current.runtimes.runtime_name

    $previousNames =
        $Previous.runtimes.runtime_name

    $newRuntimes =
        $currentNames |
        Where-Object {
            $_ -notin $previousNames
        }

    $removedRuntimes =
        $previousNames |
        Where-Object {
            $_ -notin $currentNames
        }

    return @{

        generated_at =
            (Get-Date).ToString("o")

        architecture_summary = @{

            current_runtime_count =
                $Current.runtime_count

            previous_runtime_count =
                $Previous.runtime_count

            new_runtime_count =
                $newRuntimes.Count

            removed_runtime_count =
                $removedRuntimes.Count
        }

        detected_changes = @{

            new_runtimes =
                @($newRuntimes)

            removed_runtimes =
                @($removedRuntimes)
        }

        architecture_health = @{

            drift_detected =
                (
                    $newRuntimes.Count -gt 0
                ) -or (
                    $removedRuntimes.Count -gt 0
                )

            evolution_state =
                if (
                    $newRuntimes.Count -gt 0
                ) {
                    "EVOLVING"
                }
                else {
                    "STABLE"
                }
        }
    }
}

$currentTopology =
    Get-RuntimeTopology `
        -Directory $RuntimeDirectory

$previousTopology =
    Get-JsonState `
        -Path $PreviousArchitecturePath

if (
    $null -eq $previousTopology.runtimes
) {

    $previousTopology =
        $currentTopology
}

$diff =
    Compare-Architectures `
        -Current $currentTopology `
        -Previous $previousTopology

Save-JsonState `
    -Object $currentTopology `
    -Path $CurrentArchitecturePath

Save-JsonState `
    -Object $currentTopology `
    -Path $PreviousArchitecturePath

Save-JsonState `
    -Object $diff `
    -Path $DiffPath

Write-Host ""
Write-Host "ARCHITECTURE DIFF ANALYSIS COMPLETE"
Write-Host ""

