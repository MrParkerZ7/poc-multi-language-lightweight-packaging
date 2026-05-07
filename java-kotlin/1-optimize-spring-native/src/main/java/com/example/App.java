package com.example;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.Banner;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;

import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@SpringBootApplication
public class App implements CommandLineRunner {

    public static void main(String[] args) {
        new SpringApplicationBuilder(App.class)
            .web(WebApplicationType.NONE)
            .bannerMode(Banner.Mode.OFF)
            .logStartupInfo(false)
            .run(args);
    }

    @Override
    public void run(String... args) throws Exception {
        Map<String, String> out = new LinkedHashMap<>();
        out.put("hello", "world");
        out.put("language", "java");
        out.put("uuid", UUID.randomUUID().toString());
        out.put("timestamp", DateTimeFormatter.ISO_INSTANT.format(
            Instant.now().truncatedTo(ChronoUnit.SECONDS)));
        System.out.println(new ObjectMapper().writeValueAsString(out));
    }
}
