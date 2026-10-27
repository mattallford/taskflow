<#
.SYNOPSIS
    Smoke tests a TaskFlow deployment through its Ingress.

.DESCRIPTION
    Octopus runs this on the k8s-macos Kubernetes agent, inside the cluster. The
    *.localhost hostnames only resolve on the Mac, so the script calls Traefik's
    in-cluster Service and sends the app's hostname in the Host header. That's the
    same Ingress route a browser uses.

    It checks that /health is Healthy and reports the expected version, retrying
    while the rollout settles, then checks that the web app and the tasks API respond.

.EXAMPLE
    # From an Octopus step (Script parameters):
    -AppHost "#{AppHost}" -ExpectedVersion "#{Octopus.Release.Number}"

.EXAMPLE
    # From the Mac, through Traefik's LoadBalancer address:
    ./Invoke-SmokeTest.ps1 -AppHost taskflow-dev.localhost -ExpectedVersion 1.1.46 -BaseUrl http://localhost
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AppHost,

    [Parameter(Mandatory)]
    [string]$ExpectedVersion,

    [string]$BaseUrl = "http://traefik.kube-system.svc.cluster.local",

    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

# Write-Highlight only exists when Octopus runs the script
function Write-Result([string]$Message) {
    if (Get-Command Write-Highlight -ErrorAction SilentlyContinue) {
        Write-Highlight $Message
    }
    else {
        Write-Host $Message
    }
}

function Invoke-AppRequest([string]$Path) {
    # SkipHttpErrorCheck returns 4xx/5xx responses instead of throwing, so the status can be reported
    Invoke-WebRequest -Uri "$BaseUrl$Path" -Headers @{ Host = $AppHost } -TimeoutSec 5 -SkipHttpErrorCheck
}

Write-Host "Smoke testing $AppHost (expecting version $ExpectedVersion)"

# The rollout can take a moment to settle, so retry the health check until the timeout
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$attempt = 0
do {
    $attempt++
    $health = $null
    try {
        $response = Invoke-AppRequest "/health"
        if ($response.Headers["Content-Type"] -match "json") {
            $health = $response.Content | ConvertFrom-Json
        }
        else {
            Write-Host "Attempt ${attempt}: /health returned $($response.StatusCode) without a JSON body"
        }
    }
    catch {
        Write-Host "Attempt ${attempt}: no response ($($_.Exception.Message))"
    }

    if ($health.status -eq "Healthy" -and $health.version -eq $ExpectedVersion) {
        break
    }
    if ($health) {
        Write-Host "Attempt ${attempt}: status '$($health.status)', version '$($health.version)'"
    }
    Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)

$failures = @()

if ($health.status -eq "Healthy" -and $health.version -eq $ExpectedVersion) {
    Write-Host "PASS /health is Healthy and reports version $($health.version)"
}
else {
    $failures += "/health reports status '$($health.status)' and version '$($health.version)', expected Healthy and $ExpectedVersion"
}

foreach ($path in "/", "/api/tasks") {
    try {
        $status = (Invoke-AppRequest $path).StatusCode
    }
    catch {
        $status = "no response"
    }

    if ($status -eq 200) {
        Write-Host "PASS $path returned 200"
    }
    else {
        $failures += "$path returned $status"
    }
}

if ($failures) {
    $failures | ForEach-Object { Write-Host "FAIL $_" }
    throw "Smoke test failed for http://$AppHost"
}

Write-Result "Smoke test passed: [http://$AppHost](http://$AppHost) is running $ExpectedVersion"
