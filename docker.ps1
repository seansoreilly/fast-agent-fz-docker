$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$tag = "fast-agent-fz:$timestamp"

docker rm -f fast-agent-fz 2>$null

docker build -f Dockerfile -t $tag .

if ($LASTEXITCODE -eq 0) {
    docker run -d --name fast-agent-fz -p 7681:7681 $tag
} 