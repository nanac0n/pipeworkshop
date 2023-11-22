package com.ctrlcv.er_sentinel_manager.data.repository;

import com.ctrlcv.er_sentinel_manager.data.entity.EmergencyRoom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface EmergencyRoomRepository extends JpaRepository<EmergencyRoom, Integer> {
    Optional<EmergencyRoom> findByEmergencyRoomDutyId(String dutyId);
}
