$baseUrl = "http://localhost:5184"

Write-Host "=========================================="
Write-Host "STARTING END-TO-END EVENTPASS API TESTS"
Write-Host "=========================================="

# Wait for server to be responsive
$attempts = 0
$serverReady = $false
while ($attempts -lt 30) {
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($res.status -eq "Online") {
            $serverReady = $true
            break
        }
    } catch {
        Start-Sleep -Milliseconds 500
        $attempts++
    }
}

if (-not $serverReady) {
    Write-Error "Server did not become ready in time."
    exit 1
}

Write-Host "[OK] Server is online and ready."

# 1. GET /api/events
Write-Host "`n--- TEST 1: GET /api/events ---"
$events = Invoke-RestMethod -Uri "$baseUrl/api/events" -Method Get
Write-Host "Events count: $($events.Count)"
if ($events.Count -eq 0) {
    Write-Error "No events returned from seeded database!"
    exit 1
}
$eventId = $events[0].id
Write-Host "[OK] Selected Event ID: $eventId ($($events[0].title))"

# 2. POST /api/auth/register (New User)
Write-Host "`n--- TEST 2: POST /api/auth/register ---"
$uniqueEmail = "student_$([Guid]::NewGuid().ToString().Substring(0,8))@example.com"
$registerBody = @{
    fullName = "John Doe"
    email = $uniqueEmail
    phone = "+1234567890"
    password = "SecurePassword123!"
} | ConvertTo-Json

$regResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
Write-Host "[OK] Registered User: $($regResponse.user.fullName) (ID: $($regResponse.user.id), Email: $($regResponse.user.email))"
Write-Host "[OK] JWT Token received: $($regResponse.token.Substring(0,25))..."
if (-not $regResponse.token) {
    Write-Error "Registration did not return a JWT token!"
    exit 1
}
$jwtToken = $regResponse.token
$headers = @{ "Authorization" = "Bearer $jwtToken" }

# 3. POST /api/auth/register (Duplicate Email Test)
Write-Host "`n--- TEST 3: Duplicate Email Rejection ---"
try {
    Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method Post -Body $registerBody -ContentType "application/json" -ErrorAction Stop
    Write-Error "Duplicate registration did NOT fail as expected!"
    exit 1
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "[OK] Duplicate registration correctly rejected with HTTP $statusCode"
    if ($statusCode -ne 409) {
        Write-Error "Expected HTTP 409 Conflict, got $statusCode"
        exit 1
    }
}

# 4. POST /api/auth/login
Write-Host "`n--- TEST 4: POST /api/auth/login ---"
$loginBody = @{
    email = $uniqueEmail
    password = "SecurePassword123!"
} | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
Write-Host "[OK] Logged in successfully: $($loginResponse.user.fullName)"
if (-not $loginResponse.token) {
    Write-Error "Login did not return a JWT token!"
    exit 1
}

# 5. POST /api/auth/login (Bad Password)
Write-Host "`n--- TEST 5: Login Bad Password Rejection ---"
try {
    $badLogin = @{ email = $uniqueEmail; password = "WrongPassword!" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $badLogin -ContentType "application/json" -ErrorAction Stop
    Write-Error "Bad password login did NOT fail as expected!"
    exit 1
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "[OK] Bad login correctly rejected with HTTP $statusCode"
}

# 6. POST /api/registrations (Register for Event)
Write-Host "`n--- TEST 6: POST /api/registrations ---"
$regForEventBody = @{ eventId = $eventId } | ConvertTo-Json
$eventReg = Invoke-RestMethod -Uri "$baseUrl/api/registrations" -Method Post -Body $regForEventBody -Headers $headers -ContentType "application/json"
Write-Host "[OK] Event registration created. ID: $($eventReg.id), Status: $($eventReg.status)"
Write-Host "[OK] Backend Generated QR Token: $($eventReg.qrToken)"
if (-not $eventReg.qrToken) {
    Write-Error "No QR Token generated!"
    exit 1
}
$qrToken = $eventReg.qrToken

# 7. POST /api/registrations (Duplicate Event Registration Test)
Write-Host "`n--- TEST 7: Duplicate Event Registration Rejection ---"
try {
    Invoke-RestMethod -Uri "$baseUrl/api/registrations" -Method Post -Body $regForEventBody -Headers $headers -ContentType "application/json" -ErrorAction Stop
    Write-Error "Duplicate event registration did NOT fail as expected!"
    exit 1
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "[OK] Duplicate event registration correctly rejected with HTTP $statusCode"
}

# 8. GET /api/registrations/my-pass
Write-Host "`n--- TEST 8: GET /api/registrations/my-pass ---"
$myPass = Invoke-RestMethod -Uri "$baseUrl/api/registrations/my-pass" -Method Get -Headers $headers
Write-Host "[OK] My Pass retrieved for: $($myPass.eventTitle)"
Write-Host "[OK] Pass Attendee: $($myPass.attendeeName) ($($myPass.attendeeEmail))"
Write-Host "[OK] Pass Token: $($myPass.qrToken)"
if ($myPass.qrToken -ne $qrToken) {
    Write-Error "Retrieved pass token does not match registered token!"
    exit 1
}

# 9. POST /api/scanner/scan (1st Scan: Should be Valid)
Write-Host "`n--- TEST 9: POST /api/scanner/scan (Valid Check-In) ---"
$scanBody1 = @{ qrToken = $qrToken; scannedBy = "Gate 1 Turnstile" } | ConvertTo-Json
$scan1 = Invoke-RestMethod -Uri "$baseUrl/api/scanner/scan" -Method Post -Body $scanBody1 -ContentType "application/json"
Write-Host "[OK] Scan 1 Success: $($scan1.success)"
Write-Host "[OK] Scan 1 Status: '$($scan1.status)'"
Write-Host "[OK] Scan 1 Message: $($scan1.message)"
Write-Host "[OK] Attendee Checked In: $($scan1.attendeeName) at $($scan1.checkedInAt)"
if ($scan1.status -ne "valid" -or -not $scan1.success) {
    Write-Error "Expected scan1 status to be 'valid' and success to be true!"
    exit 1
}

# 10. POST /api/scanner/scan (2nd Scan: Should be Already Checked In)
Write-Host "`n--- TEST 10: POST /api/scanner/scan (Already Checked In) ---"
$scan2 = Invoke-RestMethod -Uri "$baseUrl/api/scanner/scan" -Method Post -Body $scanBody1 -ContentType "application/json"
Write-Host "[OK] Scan 2 Success: $($scan2.success)"
Write-Host "[OK] Scan 2 Status: '$($scan2.status)'"
Write-Host "[OK] Scan 2 Message: $($scan2.message)"
if ($scan2.status -ne "already checked in" -or $scan2.success) {
    Write-Error "Expected scan2 status to be 'already checked in' and success to be false!"
    exit 1
}

# 11. POST /api/scanner/scan (Invalid Token)
Write-Host "`n--- TEST 11: POST /api/scanner/scan (Invalid Token) ---"
$badScanBody = @{ qrToken = "fake-nonexistent-token-12345"; scannedBy = "Gate 1 Turnstile" } | ConvertTo-Json
$scan3 = Invoke-RestMethod -Uri "$baseUrl/api/scanner/scan" -Method Post -Body $badScanBody -ContentType "application/json"
Write-Host "[OK] Scan 3 Success: $($scan3.success)"
Write-Host "[OK] Scan 3 Status: '$($scan3.status)'"
Write-Host "[OK] Scan 3 Message: $($scan3.message)"
if ($scan3.status -ne "invalid" -or $scan3.success) {
    Write-Error "Expected scan3 status to be 'invalid' and success to be false!"
    exit 1
}

# 12. POST /api/scanner/scan (Inactive Event Token)
Write-Host "`n--- TEST 12: POST /api/scanner/scan (Inactive Event Token) ---"
$inactiveEventBody = @{
    title = "Deactivated Test Event"
    description = "Test event that will be deactivated"
    location = "Hall B"
    eventDate = (Get-Date).AddDays(2).ToString("o")
} | ConvertTo-Json
$inactiveEvent = Invoke-RestMethod -Uri "$baseUrl/api/events" -Method Post -Body $inactiveEventBody -ContentType "application/json"

# Register user 2 for event
$user2Email = "student2_$([Guid]::NewGuid().ToString().Substring(0,8))@example.com"
$reg2Body = @{ fullName = "Jane Doe"; email = $user2Email; password = "SecurePassword123!" } | ConvertTo-Json
$user2 = Invoke-RestMethod -Uri "$baseUrl/api/auth/register" -Method Post -Body $reg2Body -ContentType "application/json"
$user2Headers = @{ "Authorization" = "Bearer $($user2.token)" }

$reg2Event = Invoke-RestMethod -Uri "$baseUrl/api/registrations" -Method Post -Body (@{ eventId = $inactiveEvent.id } | ConvertTo-Json) -Headers $user2Headers -ContentType "application/json"
$user2QrToken = $reg2Event.qrToken

# Deactivate the event via API
$deactivateRes = Invoke-RestMethod -Uri "$baseUrl/api/events/$($inactiveEvent.id)/status" -Method Patch -Body "false" -ContentType "application/json"
Write-Host "[OK] Event deactivated: $($deactivateRes.isActive)"

# Scan user 2 QR token
$scan4 = Invoke-RestMethod -Uri "$baseUrl/api/scanner/scan" -Method Post -Body (@{ qrToken = $user2QrToken; scannedBy = "Gate 2 Turnstile" } | ConvertTo-Json) -ContentType "application/json"
Write-Host "[OK] Scan 4 Success: $($scan4.success)"
Write-Host "[OK] Scan 4 Status: '$($scan4.status)'"
Write-Host "[OK] Scan 4 Message: $($scan4.message)"
if ($scan4.status -ne "inactive" -or $scan4.success) {
    Write-Error "Expected scan4 status to be 'inactive' and success to be false!"
    exit 1
}

Write-Host "`n=========================================="
Write-Host "ALL 12 TESTS PASSED PERFECTLY! "
Write-Host "=========================================="
