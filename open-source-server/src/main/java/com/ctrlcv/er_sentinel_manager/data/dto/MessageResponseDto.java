package com.ctrlcv.er_sentinel_manager.data.dto;

import com.ctrlcv.er_sentinel_manager.data.entity.EmergencyMessage;
import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class MessageResponseDto {
    private String dutyId;
    private String emgMessage;
    private LocalDateTime emgMsgStartTime;
    private LocalDateTime emgMsgEndTime;
    private String emgMsgType;

    public MessageResponseDto(EmergencyMessage emergencyMessage) {
        this.dutyId = dutyId;
        this.emgMessage = emgMessage;
        this.emgMsgStartTime = emgMsgStartTime;
        this.emgMsgEndTime = emgMsgEndTime;
        this.emgMsgType = emgMsgType;
    }
}
