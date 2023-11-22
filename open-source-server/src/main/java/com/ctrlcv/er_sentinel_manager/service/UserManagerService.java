package com.ctrlcv.er_sentinel_manager.service;

import com.ctrlcv.er_sentinel_manager.data.entity.User;
import com.ctrlcv.er_sentinel_manager.data.repository.EmergencyMessageRepository;
import com.ctrlcv.er_sentinel_manager.data.repository.EmergencyRoomRepository;
import com.ctrlcv.er_sentinel_manager.data.repository.HospitalRepository;
import com.ctrlcv.er_sentinel_manager.data.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserManagerService {
    private final UserRepository userRepository;

    public UserManagerService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public List<User> getAllUserList() {
        return userRepository.findAll();
    }

    public void deleteUserByUserId(String username) {
        userRepository.deleteByUsername(username);
    }
}
