$template = "D:\VS CoDe\Project\netMaze\arm\netmaze.json"
$templatepara = "D:\VS CoDe\Project\netMaze\arm\netmaze.prodparameters.json"

New-AzResourceGroupDeployment `
-Name projectDeploy `
-ResourceGroupName pratul233 `
-TemplateFile $template `
-TemplateParameterFile $templatepara -verbose


