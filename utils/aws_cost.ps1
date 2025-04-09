$startDate = (Get-Date).AddHours(-24).ToString("yyyy-MM-dd")
$endDate = (Get-Date).ToString("yyyy-MM-dd")

aws ce get-cost-and-usage `
  --time-period "Start=$startDate,End=$endDate" `
  --granularity DAILY `
  --metrics "AmortizedCost"
