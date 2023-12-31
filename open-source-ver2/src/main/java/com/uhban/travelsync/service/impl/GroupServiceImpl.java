package com.uhban.travelsync.service.impl;

import com.uhban.travelsync.data.dto.group.*;
import com.uhban.travelsync.data.entity.Group;
import com.uhban.travelsync.data.entity.Group_User;
import com.uhban.travelsync.data.entity.Tour;
import com.uhban.travelsync.data.entity.User;
import com.uhban.travelsync.data.repository.GroupRepository;
import com.uhban.travelsync.data.repository.GroupUserRepository;
import com.uhban.travelsync.data.repository.TourRepository;
import com.uhban.travelsync.data.repository.UserRepository;
import com.uhban.travelsync.service.GroupService;
import jakarta.persistence.EntityNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
public class GroupServiceImpl implements GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupUserRepository groupUserRepository;
    private final BCryptPasswordEncoder bCryptPasswordEncoder;
    private final TourRepository tourRepository;

    public GroupServiceImpl(GroupRepository groupRepository, UserRepository userRepository, GroupUserRepository groupUserRepository, BCryptPasswordEncoder bCryptPasswordEncoder, TourRepository tourRepository) {
        this.groupRepository = groupRepository;
        this.userRepository = userRepository;
        this.groupUserRepository = groupUserRepository;
        this.bCryptPasswordEncoder = bCryptPasswordEncoder;
        this.tourRepository = tourRepository;
    }
    @Transactional
    public List<GroupInfoDto> getGroupByUserId(String userId) {
        Optional<List<Group>> optionalGroups = groupRepository.findByUserId(userId);

        if(optionalGroups.isPresent()) {
            List<Group> groups = optionalGroups.get();

            return groups.stream()
                    .map(group -> GroupInfoDto.builder()
                            .groupId(group.getGroupId())
                            .guide(group.getGuide().getName()) // 가이드의 이름
                            .groupName(group.getGroupName())
                            .startDate(group.getStartDate())
                            .endDate(group.getEndDate())
                            .tourCompany(group.getTourCompany())
                            .build())
                    .collect(Collectors.toList());
        } else {
            //없을 경우 빈 리스트 반환
            return Collections.emptyList();
        }
    }
    @Transactional
    public GroupResponseDto getGroup(Long groupId) {
        Group group = groupRepository.findByGroupId(groupId)
                .orElseThrow(() -> {
                    log.error("해당 그룹 : {}를 찾을 수 없습니다. : ", groupId);
                    throw new IllegalArgumentException("해당 그룹을 찾을 수 없습니다. : " + groupId);
                });
        Long tourId = Optional.ofNullable(group.getTour())
                .map(Tour::getTourId)
                .orElse(null);

        return GroupResponseDto.builder()
                .groupId(group.getGroupId())
                .guide(group.getGuide().getUserId())
                .groupName(group.getGroupName())
                .startDate(group.getStartDate())
                .endDate(group.getEndDate())
                .nation(group.getNation())
                .tourCompany(group.getTourCompany())
                .toggleLoc(group.getToggleLoc())
                .tourId(tourId)
                .build();
    }

    @Transactional(readOnly = true)
    public List<GroupMemberDto> getGroupMembers(Long groupId) {
        log.info("[GroupServiceImpl] getGroupMembers groupId : {}", groupId);
        return groupRepository.findById(groupId)
                .map(group -> group.getGroupUsers()
                        .stream()
                        .map(groupUser -> GroupMemberDto.builder()
                                .groupId(groupId)
                                .userId(groupUser.getUser().getUserId())
                                .userName(groupUser.getUser().getName())
                                .build())
                        .collect(Collectors.toList()))
                .orElseThrow(() -> new EntityNotFoundException("Group not found with id: " + groupId));
    }

    @Transactional
    public GroupResponseDto saveGroup(GroupCreateDto groupCreateDto) {
        log.info("[GroupServiceImpl] saveGroup groupName : {}", groupCreateDto.getGroupName());
        // 사용자 찾기 및 그룹 생성
        User guide = userRepository.findByUserId(groupCreateDto.getGuide())
                .orElseThrow(() -> {
                    log.error("해당 사용자 : {}를 찾을 수 없습니다. : ", groupCreateDto.getGuide());
                    throw new IllegalArgumentException("해당 사용자를 찾을 수 없습니다. : " + groupCreateDto.getGuide());
                });

        Group group = Group.builder()
                .guide(guide)
                .groupName(groupCreateDto.getGroupName())
                .startDate(groupCreateDto.getStartDate())
                .endDate(groupCreateDto.getEndDate())
                .nation(groupCreateDto.getNation())
                .tourCompany(groupCreateDto.getTourCompany())
                .groupPassword(bCryptPasswordEncoder.encode(groupCreateDto.getGroupPassword()))
                .build();

        groupRepository.save(group);

        // Group_User에 가이드 추가
        Group_User groupUser = Group_User.builder()
                .user(guide)
                .group(group)
                .build();

        groupUserRepository.save(groupUser); // groupUserRepository는 Group_User 엔티티를 처리하는 JPA 리포지토리

        log.info("[GroupServiceImpl] saveGroup Success : {}", group.getGroupId());
        return GroupResponseDto.builder()
                .groupId(group.getGroupId())
                .guide(group.getGuide().getUserId())
                .groupName(group.getGroupName())
                .startDate(group.getStartDate())
                .endDate(group.getEndDate())
                .nation(group.getNation())
                .tourCompany(group.getTourCompany())
                .toggleLoc(group.getToggleLoc())
                .build();
    }

    @Transactional
    public GroupResponseDto changeGroup(GroupDto groupDto){
        log.info("[GroupServiceImpl] changeGroup groupId : {}", groupDto.getGroupId());
        Group group = groupRepository.findByGroupId(groupDto.getGroupId())
                .orElseThrow(() -> {
                    log.error("해당 그룹 : {}를 찾을 수 없습니다. : ", groupDto.getGroupId());
                    throw new IllegalArgumentException("해당 그룹을 찾을 수 없습니다. : " + groupDto.getGroupId());
                });

        // Update fields of the existing group
        group.setGroupName(groupDto.getGroupName());
        group.setStartDate(groupDto.getStartDate());
        group.setEndDate(groupDto.getEndDate());
        group.setNation(groupDto.getNation());
        group.setTourCompany(groupDto.getTourCompany());
        group.setToggleLoc(groupDto.getToggleLoc());

        // If tourId is present in the DTO, update the tour as well
        if (groupDto.getTourId() != null) {
            Tour tour = tourRepository.findById(groupDto.getTourId())
                    .orElseThrow(() -> {
                        log.error("해당 여행 : {}를 찾을 수 없습니다. : ", groupDto.getTourId());
                        throw new IllegalArgumentException("해당 여행을 찾을 수 없습니다. : " + groupDto.getTourId());
                    });
            group.setTour(tour);
        }
        groupRepository.save(group);

        return GroupResponseDto.builder()
                .groupId(group.getGroupId())
                .guide(group.getGuide().getUserId()) // Assuming getGuide() returns a User entity
                .groupName(group.getGroupName())
                .startDate(group.getStartDate())
                .endDate(group.getEndDate())
                .nation(group.getNation())
                .tourCompany(group.getTourCompany())
                .toggleLoc(group.getToggleLoc())
                .tourId(group.getTour().getTourId())
                .build();
    }


    @Transactional
    public GroupInfoDto joinGroup(String userId, GroupJoinDto groupJoinDto){
        log.info("[GroupServiceImpl] joinGroup userId : {} groupId {}", userId, groupJoinDto.getGroupId());
        Group group = groupRepository.findByGroupId(groupJoinDto.getGroupId())
                .orElseThrow(() -> {
                    log.error("해당 그룹 : {}를 찾을 수 없습니다. : ", groupJoinDto.getGroupId());
                    throw new IllegalArgumentException("해당 그룹을 찾을 수 없습니다. : " + groupJoinDto.getGroupId());
                });
        if(!bCryptPasswordEncoder.matches(groupJoinDto.getGroupPassword(), group.getGroupPassword())){
            log.error("[GroupServiceImpl] joinGroup 비밀번호가 일치하지 않습니다.");
            throw new IllegalArgumentException("비밀번호가 일치하지 않습니다.");
        }
        log.info("[GroupServiceImpl] joinGroup guideName : {}", group.getGuide().getName());
        User user = userRepository.findByUserId(userId)
                .orElseThrow(() -> {
                    log.error("해당 사용자 : {}를 찾을 수 없습니다. : ", userId);
                    throw new IllegalArgumentException("해당 사용자를 찾을 수 없습니다. : " + userId);
                });
        Group_User groupUser = Group_User.builder()
                .user(user)
                .group(group)
                .build();
        groupUserRepository.save(groupUser);
        log.info("[GroupServiceImpl] joinGroup Success : {} {}", userId, groupJoinDto.getGroupId());
        return GroupInfoDto.builder()
                .groupId(group.getGroupId())
                .guide(group.getGuide().getName()) // 가이드의 이름
                .groupName(group.getGroupName())
                .startDate(group.getStartDate())
                .endDate(group.getEndDate())
                .tourCompany(group.getTourCompany())
                .build();

    }
    @Transactional
    public boolean isUserInGroup(String userId, Long groupId){
        log.info("[GroupServiceImpl] isUserInGroup userId : {} groupId {}", userId, groupId);
        return groupUserRepository.existsByUser_UserIdAndGroup_GroupId(userId, groupId);
    }

    @Transactional
    public void deleteGroup(Long groupId){
        log.info("[GroupServiceImpl] deleteGroup groupId : {}", groupId);
        //group 삭제
        Group group = groupRepository.findByGroupId(groupId)
                .orElseThrow(() -> {
                    log.error("해당 그룹 : {}를 찾을 수 없습니다. : ", groupId);
                    throw new IllegalArgumentException("해당 그룹을 찾을 수 없습니다. : " + groupId);
                });
        groupRepository.delete(group);
        log.info("[GroupServiceImpl] deleteGroup Success : {}", groupId);
    }

    @Transactional
    public void leaveGroup(String userId, Long groupId){
        log.info("[GroupServiceImpl] leaveGroup userId : {} groupId {}", userId, groupId);
        //group에서 탈퇴 GroupUser 삭제
        Group_User groupUser = groupUserRepository.findByUser_UserIdAndGroup_GroupId(userId, groupId)
                .orElseThrow(() -> {
                    log.error("해당 그룹 : {}를 찾을 수 없습니다. : ", groupId);
                    throw new IllegalArgumentException("해당 그룹을 찾을 수 없습니다. : " + groupId);
                });
        groupUserRepository.delete(groupUser);
        log.info("[GroupServiceImpl] leaveGroup Success : {} {}", userId, groupId);
    }

}
