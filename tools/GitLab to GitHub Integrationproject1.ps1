@echo off

mkdir lokalerepo
cd lokalerepo
git clone https://gitlab.com/kdg-ti/integratieproject-1/202324/23_codeforge/development
cd development
git push --mirror https://github.com/EliasDeHondt/IntegrationProject1-Development.git
cd ..
git clone https://gitlab.com/kdg-ti/integratieproject-1/202324/23_codeforge/deployment
cd development
git push --mirror https://github.com/EliasDeHondt/IntegrationProject1-Deployment.git
cd ..
cd ..
rmdir /s /q lokalerepo