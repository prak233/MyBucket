$template = "D:\VS CoDe\Project\netMaze\arm\netmaze.json"
$templatepara = "D:\VS CoDe\Project\netMaze\arm\netmaze.testparameters.json"

New-AzResourceGroupDeployment `
-Name armDeploy `
-ResourceGroupName pratul233 `
-TemplateFile $template `
-TemplateParameterFile $templatepara -verbose


