package com.example;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.runtime.annotations.QuarkusMain;
import io.quarkus.runtime.QuarkusApplication;
import jakarta.inject.Inject;
import picocli.CommandLine;

import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;

@QuarkusMain
@CommandLine.Command(name = "app", mixinStandardHelpOptions = true)
public class App implements Callable<Integer>, QuarkusApplication {

    @Override
    public Integer call() throws Exception {
        Map<String, String> out = new LinkedHashMap<>();
        out.put("hello", "world");
        out.put("language", "java");
        out.put("uuid", UUID.randomUUID().toString());
        out.put("timestamp", DateTimeFormatter.ISO_INSTANT.format(
            Instant.now().truncatedTo(ChronoUnit.SECONDS)));
        System.out.println(new ObjectMapper().writeValueAsString(out));
        return 0;
    }

    @Override
    public int run(String... args) {
        return new CommandLine(this).execute(args);
    }
}
