$template = "D:\VS CoDe\Project\netMaze\bicep\netMaze.bicep"
$templatepara = "D:\VS CoDe\Project\netMaze\bicep\netMaze.test.bicepparam"

New-AzResourceGroupDeployment `
-Name bicepDeploy `
-ResourceGroupName pratul233 `
-TemplateFile $template `
-TemplateParameterFile $templatepara -verbose


