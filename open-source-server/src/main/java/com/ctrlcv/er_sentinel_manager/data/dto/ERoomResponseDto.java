package com.ctrlcv.er_sentinel_manager.data.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class ERoomResponseDto {
    private String dutyId;
    private String name;
    private String phoneNumber;
    private int pediatricAvailableBeds;
    private int pediatricStandardBeds;
    private int adultAvailableBeds;
    private int adultStandardBeds;
    private LocalDateTime apiUpdateTime;
    private LocalDateTime updateTime;
}
