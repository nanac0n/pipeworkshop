package com.ctrlcv.er_sentinel_manager.data.dto;

import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class HospitalResponseDto {
    private String dutyId;
    private String name;
    private String phoneNumber;
    private String longitude;
    private String latitude;
    private String address;
    private String firstAddress;
    private String secondAddress;
    private String updateTime;
}
