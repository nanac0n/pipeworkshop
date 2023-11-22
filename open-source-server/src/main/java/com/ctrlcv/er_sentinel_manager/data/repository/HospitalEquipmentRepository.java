package com.ctrlcv.er_sentinel_manager.data.repository;

import com.ctrlcv.er_sentinel_manager.data.entity.HospitalEquipment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface HospitalEquipmentRepository extends JpaRepository<HospitalEquipment, Integer> {
    Optional<HospitalEquipment> findByHospitalDutyId(String dutyId);
}

