package com.ctrlcv.er_sentinel_manager.data.repository;

import com.ctrlcv.er_sentinel_manager.data.entity.EmergencyMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EmergencyMessageRepository extends JpaRepository<EmergencyMessage, Integer> {
    List<EmergencyMessage> findByEmergencyMessageDutyId(String dutyId);
}
