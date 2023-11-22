package com.ctrlcv.er_sentinel_manager.service;

import com.ctrlcv.er_sentinel_manager.data.entity.Log;
import com.ctrlcv.er_sentinel_manager.data.repository.LogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class LogService {

    @Autowired
    private LogRepository logRepository;

    public List<Log> getLogs(){
        return logRepository.findAll();
    }
}
