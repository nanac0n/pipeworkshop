package com.ctrlcv.er_sentinel_manager.data.repository;

import com.ctrlcv.er_sentinel_manager.data.entity.EmergencyRoomSevereCapacityInfo;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface EmergencyRoomSevereCapacityInfoRepository extends JpaRepository<EmergencyRoomSevereCapacityInfo, Integer> {
    Optional<EmergencyRoomSevereCapacityInfo> findByEmergencyRoomSevereCapacityInfodutyId(String dutyId);
}
