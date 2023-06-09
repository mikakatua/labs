import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;
import javax.sql.DataSource;
import org.postgresql.jdbc2.optional.SimpleDataSource;

public class JdbcExample {
    public static void main(String[] args) {
        // Load the configuration from the properties file
        Properties properties = new Properties();
        try (FileInputStream fis = new FileInputStream("config.properties")) {
            properties.load(fis);
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }

        // Create a DataSource object with the configured properties
        SimpleDataSource dataSource = new SimpleDataSource();
        dataSource.setURL(properties.getProperty("database.url"));
        dataSource.setUser(properties.getProperty("database.username"));
        dataSource.setPassword(properties.getProperty("database.password"));

       // Print server IP address
       try (Connection connection = dataSource.getConnection();
             Statement statement = connection.createStatement()) {

            String query = "SELECT inet_server_addr() AS server_ip";
            ResultSet resultSet = statement.executeQuery(query);

            if (resultSet.next()) {
                String serverIP = resultSet.getString("server_ip");
                System.out.println("Server IP Address: " + serverIP);
            } else {
                System.out.println("No result found.");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        // Execute a query
        try (Connection connection = dataSource.getConnection();
             Statement statement = connection.createStatement()) {

            String query = "SELECT * FROM mytable ORDER BY id";
            ResultSet resultSet = statement.executeQuery(query);

            while (resultSet.next()) {
                int id = resultSet.getInt("id");
                String name = resultSet.getString("name");
                System.out.println("ID: " + id + ", Name: " + name);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}

