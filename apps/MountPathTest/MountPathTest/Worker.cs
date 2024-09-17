using System.Text;

namespace MountPathTest
{
    internal class Worker : BackgroundService
    {
        private readonly IConfiguration configuration;
        private readonly ILogger logger;

        public Worker(IConfiguration configuration, ILogger<Worker> logger)
        {
            this.configuration = configuration;
            this.logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while(!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var path = configuration["WorkingDirectory"];
                    if (Path.Exists(path))
                    {
                        var builder = new StringBuilder();

                        var fileName = Path.Combine(path, "test.txt");
                        if (File.Exists(fileName))
                        {
                            var content = await File.ReadAllTextAsync(fileName, stoppingToken);
                            builder.Append(content);
                        }

                        builder.AppendLine($"Now: {DateTime.UtcNow}");

                        await File.WriteAllTextAsync(fileName, builder.ToString(), stoppingToken);
                    }
                    else
                    {
                        logger.LogInformation("WorkingDirectory has not been specified.");
                    }
                }
                catch (Exception ex)
                {
                    logger.LogError(ex.ToString());
                }

                await Task.Delay(1000 * 10, stoppingToken);
            }
        }
    }
}
