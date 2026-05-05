package com.example;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

public class App {
    public static void main(String[] args) throws Exception {
        Map<String, String> out = new LinkedHashMap<>();
        out.put("hello", "world");
        out.put("language", "java");
        out.put("uuid", UUID.randomUUID().toString());
        out.put("timestamp", DateTimeFormatter.ISO_INSTANT.format(
            Instant.now().truncatedTo(ChronoUnit.SECONDS)));
        System.out.println(new ObjectMapper().writeValueAsString(out));
    }
}
