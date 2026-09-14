$ErrorActionPreference = 'Stop'
if (-not $env:DCDART_WINDOWS_PUBLISHER) { throw 'Expected Windows certificate subject is required' }
$signature = Get-AuthenticodeSignature -LiteralPath $env:DCDART_VERIFY_BINARY
if ($signature.Status -ne 'Valid') { throw "Authenticode verification failed: $($signature.Status)" }
if ($signature.SignerCertificate.Subject -cne $env:DCDART_WINDOWS_PUBLISHER) { throw 'Unexpected Windows publisher' }
if (-not $signature.TimeStamperCertificate) { throw 'A trusted timestamp is required' }
@{ publisher = $signature.SignerCertificate.Subject; certificateThumbprint = $signature.SignerCertificate.Thumbprint } | ConvertTo-Json -Compress
