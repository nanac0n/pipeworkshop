package com.ctrlcv.er_sentinel_manager.controller;

import com.ctrlcv.er_sentinel_manager.data.dto.UserDto;
import com.ctrlcv.er_sentinel_manager.service.UserManagerService;
import org.apache.coyote.Response;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class UserManagerController {

    private final UserManagerService userManagerService;

    public UserManagerController(UserManagerService userManagerService) {
        this.userManagerService = userManagerService;
    }

    @GetMapping("/manager/user")
    public ResponseEntity<List<UserDto>> getAllUser() {
        List<UserDto> userDtoList = userManagerService.getAllUserList().stream()
                .map(UserDto::new)
                .toList();
        return new ResponseEntity<>(userDtoList, HttpStatus.OK);
    }

    @DeleteMapping("/manager/user")
    public ResponseEntity<String> deleteUser(@RequestBody Map<String, String> unMap) {
        String un = unMap.get("username");
        userManagerService.deleteUserByUserId(un);
        return new ResponseEntity<>("삭제 완료", HttpStatus.OK);
    }
}
