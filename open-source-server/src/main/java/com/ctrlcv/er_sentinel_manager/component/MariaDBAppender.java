package com.ctrlcv.er_sentinel_manager.component;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.UnsynchronizedAppenderBase;
import com.ctrlcv.er_sentinel_manager.data.entity.Log;
import com.ctrlcv.er_sentinel_manager.data.repository.LogRepository;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;

public class MariaDBAppender extends UnsynchronizedAppenderBase<ILoggingEvent> implements ApplicationContextAware {
    private static LogRepository logRepository;

    @Override
    protected void append(ILoggingEvent eventObject){
        Log log = new Log(eventObject.getFormattedMessage());

        logRepository.save(log);
    }

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        if(applicationContext.getAutowireCapableBeanFactory().getBean(LogRepository.class)!=null){
            logRepository = (LogRepository) applicationContext.getAutowireCapableBeanFactory().getBean(LogRepository.class);
        }
    }
}
