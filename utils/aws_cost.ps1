param(
  [Parameter(Position = 0)]
  $startDate = 1
)

# If startDate is a number, treat it as days ago
if ($startDate -match '^\d+$') {
  $dayCount = [int]$startDate
  $startDate = (Get-Date).AddDays(-$dayCount).ToString("yyyy-MM-dd")
}
else {
  # Calculate days between start date and today
  $startDateObj = [DateTime]::ParseExact($startDate, "yyyy-MM-dd", $null)
  $dayCount = (New-TimeSpan -Start $startDateObj -End (Get-Date)).Days
}

$endDate = (Get-Date).ToString("yyyy-MM-dd")

$result = aws ce get-cost-and-usage `
  --time-period "Start=$startDate,End=$endDate" `
  --granularity DAILY `
  --metrics "AmortizedCost" | ConvertFrom-Json

# Calculate total cost across all time periods
$totalCost = 0
foreach ($timeResult in $result.ResultsByTime) {
  $totalCost += [decimal]$timeResult.Total.AmortizedCost.Amount
}

# Output formatted message with days and cost
"The total cost for the last $dayCount days is `$$($totalCost.ToString("0.00"))"
