using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Serilog;

namespace Foundation
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
            var isDevelopment = environment == Environments.Development;

            if (isDevelopment)
            {
                Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Warning()
                .WriteTo.File("App_Data/log.txt", rollingInterval: RollingInterval.Day)
                .CreateLogger();
            }


            CreateHostBuilder(args, isDevelopment).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args, bool isDevelopment)
        {
            if (isDevelopment)
            {
                return Host.CreateDefaultBuilder(args)
                    .ConfigureCmsDefaults()
                    .UseSerilog()
                    // .ConfigureAppConfiguration((hostingContext, config) =>
                    // {
                    //     config.Sources.Clear();
                    //     var env = hostingContext.HostingEnvironment;
                    //     config.AddJsonFile("appsettings.json", true, true);
                    //     config.AddJsonFile($"appsettings.{env.EnvironmentName}.json", true, true);

                    //     config.AddEnvironmentVariables();
                    //     config.AddUserSecrets(typeof(Startup).Assembly, true);

                    //     if (args != null)
                    //     {
                    //         config.AddCommandLine(args);
                    //     }
                    // })
                    .ConfigureWebHostDefaults(webBuilder =>
                    {
                        webBuilder.UseStartup<Startup>();
                    });
            }
            else
            {
                return Host.CreateDefaultBuilder(args)
                    .ConfigureCmsDefaults()
                    .ConfigureWebHostDefaults(webBuilder =>
                    {
                        webBuilder.UseStartup<Startup>();
                    });
            }
        }
    }
}
