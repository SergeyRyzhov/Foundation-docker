ROOTPATH=$PWD
ROOTDIR=$PWD
SOURCEPATH=$ROOTPATH/src

APPNAME=FoundationDemo
SQLSERVER=mssql
cms_db=$APPNAME.Cms
commerce_db=$APPNAME.Commerce
user=$APPNAME.User
password=FLSMeetupNight2024
errorMessage=""

export PATH="$PATH:/opt/mssql-tools18/bin"

if [ $( sqlcmd -S $SQLSERVER -C -U SA -P $password -Q "if db_id('FoundationDemo.Cms') is not null SELECT 1;" | grep 1 | wc -l ) -gt 0 ]; then
    echo "optimizely databases exist"
else    
    dotnet new -i EPiServer.Net.Templates --nuget-source https://nuget.optimizely.com/feed/packages.svc/ --force
    dotnet tool update EPiServer.Net.Cli --global --add-source https://nuget.optimizely.com/feed/packages.svc/
    dotnet nuget add source https://nuget.optimizely.com/feed/packages.svc -n Optimizely
    dotnet dev-certs https --trust
    
    mkdir "$ROOTPATH/Build/Logs" 2>nul
    
    
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
fi

dotnet run --project src/Foundation/Foundation.csproj