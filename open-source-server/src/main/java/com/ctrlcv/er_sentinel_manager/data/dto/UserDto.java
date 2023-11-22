package com.ctrlcv.er_sentinel_manager.data.dto;

import com.ctrlcv.er_sentinel_manager.data.entity.User;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Getter
public class UserDto {
    private int id;
    private String username;
    private String password;
    private String nickname;
    private String email;
    private String role;

    public UserDto(User user) {
        this.id = user.getId();
        this.username = user.getUsername();
        this.password = user.getPassword();
        this.nickname = user.getNickname();
        this.email = user.getEmail();
        this.role = user.getRole();
    }
}
