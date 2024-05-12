ROOTPATH=$PWD
ROOTDIR=$PWD
SOURCEPATH=$ROOTPATH/src

# add_sql_container()
# {
#     if [ $( docker ps -a | grep sql_server_optimizely | wc -l ) -gt 0 ]; then
#         echo "sql_server_optimizely exists"
#     else
#         sudo docker run -d --name sql_server_optimizely -h $1 -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Episerver123!' \
#            -p 1433:1433 mcr.microsoft.com/mssql/server:2019-latest
#         docker cp ./build sql_server_optimizely:/build
#     fi
# }

# while [ -z "$APPNAME" ]; do
#     read -p "Enter your app name: " APPNAME
# done
APPNAME=FoundationDemo

#read -p "Enter your SQL server name [localhost]: " SQLSERVER
SQLSERVER=mssql
 #${SQLSERVER:-localhost}

#dotnet new -i EPiServer.Net.Templates --nuget-source https://nuget.optimizely.com/feed/packages.svc/ --force
#dotnet tool update EPiServer.Net.Cli --global --add-source https://nuget.optimizely.com/feed/packages.svc/
#dotnet nuget add source https://nuget.optimizely.com/feed/packages.svc -n Optimizely
#dotnet dev-certs https --trust

#dotnet build
#add_sql_container "$SQLSERVER"

cms_db=$APPNAME.Cms
commerce_db=$APPNAME.Commerce
user=$APPNAME.User
password=Episerver123!
errorMessage="" 

mkdir "$ROOTPATH/Build/Logs" 2>nul

#cd src/Foundation/
#npm ci
#npm run dev
#cd ../..

export PATH="$PATH:/opt/mssql-tools18/bin"
#echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
#echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
#source ~/.bashrc

sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "EXEC msdb.dbo.sp_delete_database_backuphistory N'$cms_db'"
sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "if db_id('$cms_db') is not null ALTER DATABASE [$cms_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "if db_id('$cms_db') is not null DROP DATABASE [$cms_db]"
sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "EXEC msdb.dbo.sp_delete_database_backuphistory N'$commerce_db'"
sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "if db_id('$commerce_db') is not null ALTER DATABASE [$commerce_db] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "if db_id('$commerce_db') is not null DROP DATABASE [$commerce_db]"

dotnet-episerver create-cms-database "./src/Foundation/Foundation.csproj" -S $SQLSERVER -U sa -P $password --database-name "$cms_db"  --database-user $user --database-password $password
dotnet-episerver create-commerce-database "./src/Foundation/Foundation.csproj" -S $SQLSERVER -U sa -P $password --database-name "$commerce_db" --reuse-cms-user

sqlcmd -S $SQLSERVER -C -U SA -P $password -d $commerce_db -b -i "./build/SqlScripts/FoundationConfigurationSchema.sql" -v appname=$APPNAME
sqlcmd -S $SQLSERVER -C -U SA -P $password -d $commerce_db -b -i "./build/SqlScripts/UniqueCouponSchema.sql"

dotnet run --project src/Foundation/Foundation.csproj