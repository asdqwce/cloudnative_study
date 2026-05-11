package com.medical.testsupport;

import org.junit.jupiter.api.Tag;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.lifecycle.Startables;
import org.testcontainers.utility.DockerImageName;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import java.util.stream.Stream;

@Tag("integration")
public abstract class AbstractIntegrationTest {
    private static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>(
            DockerImageName.parse("postgres:15-alpine"))
            .withDatabaseName("medical_integration")
            .withUsername("test")
            .withPassword("test");

    private static final KafkaContainer KAFKA = new KafkaContainer(
            DockerImageName.parse("confluentinc/cp-kafka:7.6.1"));

    private static final String TEST_RUN_ID = UUID.randomUUID()
            .toString()
            .replace("-", "")
            .substring(0, 12);
    private static final String POSTGRES_SCHEMA = "it_" + TEST_RUN_ID;
    private static final String APPOINTMENT_CONFIRMED_TOPIC = "appointment-confirmed-" + TEST_RUN_ID;
    private static final String NOTIFICATION_GROUP_ID = "notification-group-" + TEST_RUN_ID;

    static {
        Startables.deepStart(Stream.of(POSTGRES, KAFKA)).join();
        createPostgresSchema();
    }

    @DynamicPropertySource
    static void registerInfrastructureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> withCurrentSchema(POSTGRES.getJdbcUrl()));
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create-drop");
        registry.add("spring.jpa.properties.hibernate.default_schema", () -> POSTGRES_SCHEMA);

        registry.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
        registry.add("spring.kafka.producer.key-serializer",
                () -> "org.apache.kafka.common.serialization.StringSerializer");
        registry.add("spring.kafka.producer.value-serializer",
                () -> "org.springframework.kafka.support.serializer.JsonSerializer");
        registry.add("spring.kafka.producer.properties.spring.json.add.type.headers", () -> "false");
        registry.add("spring.kafka.consumer.group-id", () -> NOTIFICATION_GROUP_ID);
        registry.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
        registry.add("spring.kafka.consumer.key-deserializer",
                () -> "org.apache.kafka.common.serialization.StringDeserializer");
        registry.add("spring.kafka.consumer.value-deserializer",
                () -> "org.springframework.kafka.support.serializer.JsonDeserializer");
        registry.add("spring.kafka.consumer.properties.spring.json.trusted.packages", () -> "com.medical.*");
        registry.add("spring.kafka.consumer.properties.spring.json.use.type.headers", () -> "false");
        registry.add("spring.kafka.consumer.properties.spring.json.value.default.type",
                () -> "com.medical.notification.dto.AppointmentEvent");

        registry.add("medical.kafka.topic-suffix", () -> TEST_RUN_ID);
        registry.add("medical.kafka.topics.appointment-confirmed", () -> APPOINTMENT_CONFIRMED_TOPIC);
    }

    protected static String appointmentConfirmedTopic() {
        return APPOINTMENT_CONFIRMED_TOPIC;
    }

    protected static String testRunId() {
        return TEST_RUN_ID;
    }

    private static void createPostgresSchema() {
        try (var connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(),
                POSTGRES.getUsername(),
                POSTGRES.getPassword());
             var statement = connection.createStatement()) {
            statement.execute("CREATE SCHEMA IF NOT EXISTS " + POSTGRES_SCHEMA);
        } catch (SQLException exception) {
            throw new IllegalStateException("Failed to create PostgreSQL test schema " + POSTGRES_SCHEMA, exception);
        }
    }

    private static String withCurrentSchema(String jdbcUrl) {
        String separator = jdbcUrl.contains("?") ? "&" : "?";
        return jdbcUrl + separator + "currentSchema=" + POSTGRES_SCHEMA;
    }
}
