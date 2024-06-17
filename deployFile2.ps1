$template = "D:\VS CoDe\Project\netMaze\bicep\netMaze.bicep"
$templatepara = "D:\VS CoDe\Project\netMaze\bicep\netMaze.prod.bicepparam"
$rgName = 'pratul015'
$loc = 'westus'

New-AzResourceGroup -Name $rgName -Location $loc

New-AzResourceGroupDeployment `
-Name bicepDeploy `
-ResourceGroupName $rgname `
-TemplateFile $template `
-TemplateParameterFile $templatepara -verbose


