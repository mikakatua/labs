package com.example.httpsclient;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.boot.ssl.SslBundle;
import org.springframework.boot.ssl.SslBundles;
import org.springframework.boot.WebApplicationType;

import javax.net.ssl.SSLContext;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@SpringBootApplication
public class HttpsClientApplication {

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(HttpsClientApplication.class);
        app.setWebApplicationType(WebApplicationType.NONE); // Disable web server
        app.run(args);
    }

    @Bean
    public CommandLineRunner run(SslBundles sslBundles) {
        return args -> {
            if (args.length < 1) {
                System.out.println("Please provide a URL as a command-line argument");
                System.exit(1);  // Exit if no URL is provided
            }

            // URL received from the command line
            String url = args[0];

            try {
                SSLContext sslContext;

                // Check if a custom SSL bundle is defined
                SslBundle sslBundle = null;
                try {
                    sslBundle = sslBundles.getBundle("myBundle");
                } catch (Exception e) {
                    // Custom SSL bundle not found, falling back to default Java CA certificates
                    System.out.println("Custom SSL bundle not defined. Falling back to default Java CA certificates.");
                }

                // If custom SSL bundle exists, use its SSLContext. Otherwise, use the default Java SSLContext.
                if (sslBundle != null) {
                    sslContext = sslBundle.createSslContext();
                } else {
                    sslContext = SSLContext.getDefault();
                }

                // Make the HTTPS request with the selected SSL context
                HttpClient client = HttpClient.newBuilder()
                        .sslContext(sslContext)
                        .build();

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .GET()
                        .build();

                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

                // Output the response body
                System.out.println("Response: " + response.body());

                // Exit the application after printing the response
                System.exit(0);

            } catch (Exception e) {
                System.err.println("Error: " + e.getMessage());
                e.printStackTrace();
                System.exit(1);  // Exit with error code if an exception occurs
            }
        };
    }
}

