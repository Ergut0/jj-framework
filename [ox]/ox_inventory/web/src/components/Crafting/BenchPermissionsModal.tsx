import React, { useCallback, useEffect, useMemo, useState } from 'react';
import othersIcon from '../../assets/svg/permissions.svg';
import { useAppDispatch, useAppSelector } from '../../store';
import {
  BenchPermissionsPayload,
  BenchRole,
  OnlinePlayer,
  PlayerPermissions,
  closeBenchPermissions,
  selectBenchPermissions,
  setBenchPermissions,
} from '../../store/benchPermissions';
import { Locale, subscribeLocale } from '../../store/locale';
import useNuiEvent from '../../hooks/useNuiEvent';
import { fetchNui } from '../../utils/fetchNui';
import { Config } from '../../store/config';

type NuiResponse = {
  success: boolean;
  data?: BenchPermissionsPayload;
  error?: string;
};

const defaultPermissions = { use: true, move: false, pack: false, manage: false };

type PermissionKey = keyof typeof defaultPermissions;

const rolePermissionKeyMap = {
  use: 'canUse',
  move: 'canMove',
  pack: 'canPack',
  manage: 'canManage',
} as const;

const getRolePermissionValue = (role: BenchRole, key: PermissionKey) => role[rolePermissionKeyMap[key]];

const getPlayerPermissionValue = (permissions: PlayerPermissions | undefined, key: PermissionKey) => {
  if (!permissions) return false;

  switch (key) {
    case 'use':
      return permissions.canUse;
    case 'move':
      return permissions.canMove;
    case 'pack':
      return permissions.canPack;
    case 'manage':
      return permissions.canManage;
    default:
      return false;
  }
};

const getInitials = (name?: string) =>
  (name || '?')
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

type PlayerSelectOption = { value: string; label: string };

const PlayerSelect: React.FC<{
  value: string;
  options: PlayerSelectOption[];
  placeholder: string;
  disabled?: boolean;
  onChange: (value: string) => void;
}> = ({ value, options, placeholder, disabled, onChange }) => {
  const [open, setOpen] = useState(false);
  const rootRef = React.useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!open) return;

    const onPointerDown = (event: MouseEvent) => {
      if (rootRef.current && !rootRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.stopPropagation();
        setOpen(false);
      }
    };

    window.addEventListener('mousedown', onPointerDown);
    window.addEventListener('keydown', onKeyDown, true);
    return () => {
      window.removeEventListener('mousedown', onPointerDown);
      window.removeEventListener('keydown', onKeyDown, true);
    };
  }, [open]);

  useEffect(() => {
    if (disabled) setOpen(false);
  }, [disabled]);

  const selected = options.find((option) => option.value === value);

  return (
    <div className="bench-prp-select-wrap" ref={rootRef}>
      <button
        type="button"
        className={`bench-prp-input bench-prp-select-trigger${open ? ' is-open' : ''}`}
        disabled={disabled}
        onClick={() => setOpen((prev) => !prev)}
      >
        <span className={selected ? '' : 'is-placeholder'}>{selected ? selected.label : placeholder}</span>
        <i className="fas fa-chevron-down" aria-hidden="true" />
      </button>

      {open && (
        <div className="bench-prp-select-list" role="listbox">
          <button
            type="button"
            className={`bench-prp-select-option${value === '' ? ' is-active' : ''}`}
            onClick={() => {
              onChange('');
              setOpen(false);
            }}
          >
            {placeholder}
          </button>
          {options.map((option) => (
            <button
              key={option.value}
              type="button"
              className={`bench-prp-select-option${value === option.value ? ' is-active' : ''}`}
              onClick={() => {
                onChange(option.value);
                setOpen(false);
              }}
            >
              {option.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

const BenchPermissionsModal: React.FC = () => {
  const dispatch = useAppDispatch();
  const state = useAppSelector(selectBenchPermissions);

  const [selectedRoleId, setSelectedRoleId] = useState<number | null>(null);
  const [roleName, setRoleName] = useState('');
  const [permissionFlags, setPermissionFlags] = useState(defaultPermissions);
  const [newMemberIdentifier, setNewMemberIdentifier] = useState('');
  const [selectedOnlinePlayer, setSelectedOnlinePlayer] = useState('');
  const [transferTarget, setTransferTarget] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [deletePending, setDeletePending] = useState(false);
  const [, setLocaleVersion] = useState(0);

  const L = useCallback((key: string, fallback: string) => {
    const v = (Locale as Record<string, string>)[key];
    return v && v !== key ? v : fallback;
  }, []);

  const isLoadout = Config.layout === 'loadout';
  const isStorage = typeof state.benchId === 'string' && state.benchId.startsWith('storage:');

  const permissionList = isStorage
    ? [
        {
          key: 'use' as PermissionKey,
          icon: 'fa-box-open',
          label: L('storage_permission_use', 'Use Storage'),
          description: L('storage_permission_use_description', 'Can open the storage and access its inventory.'),
        },
        {
          key: 'move' as PermissionKey,
          icon: 'fa-arrows-up-down-left-right',
          label: L('storage_permission_move', 'Move Storage'),
          description: L('storage_permission_move_description', 'Can reposition the storage unit.'),
        },
        {
          key: 'pack' as PermissionKey,
          icon: 'fa-box',
          label: L('storage_permission_pack', 'Pack Storage'),
          description: L('storage_permission_pack_description', 'Can pack the storage unit back into an item.'),
        },
        {
          key: 'manage' as PermissionKey,
          icon: 'fa-users-gear',
          label: L('storage_permission_manage', 'Manage Members'),
          description: L('storage_permission_manage_description', 'Can edit roles, permissions, and members.'),
        },
      ]
    : [
        {
          key: 'use' as PermissionKey,
          icon: 'fa-hammer',
          label: L('crafting_permission_use', 'Use bench'),
          description: L('crafting_permission_use_description', 'Can open the bench and view recipes.'),
        },
        {
          key: 'move' as PermissionKey,
          icon: 'fa-arrows-up-down-left-right',
          label: L('crafting_permission_move', 'Move bench'),
          description: L('crafting_permission_move_description', 'Can move the bench position.'),
        },
        {
          key: 'pack' as PermissionKey,
          icon: 'fa-box',
          label: L('crafting_permission_pack', 'Pack bench'),
          description: L('crafting_permission_pack_description', 'Can pack the bench into an item.'),
        },
        {
          key: 'manage' as PermissionKey,
          icon: 'fa-users-gear',
          label: L('crafting_permission_manage', 'Manage members'),
          description: L('crafting_permission_manage_description', 'Can edit roles, permissions, and members.'),
        },
      ];

  useNuiEvent<BenchPermissionsPayload>('openBenchPermissions', (payload) => {
    if (payload) {
      dispatch(setBenchPermissions(payload));
    }
  });

  const formatMembersCount = useCallback(
    (count: number) => {
      const template = L('crafting_permissions_members_count', '{count} members');
      return template.replace('{count}', String(count));
    },
    [L]
  );

  const closeModal = useCallback(() => {
    fetchNui('benchPermissions:close');
    dispatch(closeBenchPermissions());
    setSelectedRoleId(null);
    setRoleName('');
    setPermissionFlags(defaultPermissions);
    setNewMemberIdentifier('');
    setSelectedOnlinePlayer('');
    setTransferTarget('');
    setErrorMessage(null);
    setDeletePending(false);
  }, [dispatch]);

  useEffect(() => {
    if (!state.open) {
      setSelectedRoleId(null);
      setRoleName('');
      setPermissionFlags(defaultPermissions);
      setNewMemberIdentifier('');
      setSelectedOnlinePlayer('');
      setTransferTarget('');
      setErrorMessage(null);
      setDeletePending(false);
      return;
    }

    if (state.roles.length === 0) {
      setSelectedRoleId(null);
      return;
    }

    setSelectedRoleId((prev) => {
      if (prev == null) return state.roles[0].id;
      const exists = state.roles.find((role) => role.id === prev);
      return exists ? prev : state.roles[0].id;
    });
  }, [state.open, state.roles]);

  useEffect(() => {
    const unsub = subscribeLocale(() => setLocaleVersion((v) => v + 1));
    return unsub;
  }, []);

  useEffect(() => {
    if (!state.open) return;

    if (selectedRoleId == null) {
      setRoleName('');
      setPermissionFlags(defaultPermissions);
      setDeletePending(false);
      return;
    }

    const role = state.roles.find((entry) => entry.id === selectedRoleId);
    if (!role) {
      setRoleName('');
      setPermissionFlags(defaultPermissions);
      setDeletePending(false);
      return;
    }

    setRoleName(role.name);
    setPermissionFlags({
      use: role.canUse,
      move: role.canMove,
      pack: role.canPack,
      manage: role.canManage,
    });
    setDeletePending(false);
  }, [state.open, state.roles, selectedRoleId]);

  useEffect(() => {
    setDeletePending(false);
  }, [selectedRoleId]);

  useEffect(() => {
    if (!state.open) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        closeModal();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [state.open, closeModal]);

  const selectedRole: BenchRole | null = useMemo(
    () => (selectedRoleId != null ? state.roles.find((role) => role.id === selectedRoleId) ?? null : null),
    [state.roles, selectedRoleId]
  );

  const canManageRoles = state.isOwner || !!state.playerPermissions?.canManage;

  const selectableOnlinePlayers = useMemo(() => {
    return state.onlinePlayers.filter((player) => player.identifier !== state.owner?.identifier);
  }, [state.onlinePlayers, state.owner?.identifier]);

  const totalMembers = useMemo(
    () => state.roles.reduce((total, role) => total + role.memberCount, 0),
    [state.roles]
  );

  const allRoleMembers = useMemo(
    () =>
      state.roles.flatMap((role) =>
        role.members.map((member) => ({
          ...member,
          roleId: role.id,
          roleName: role.name,
        }))
      ),
    [state.roles]
  );

  const currentUserAccess = permissionList.filter(
    (item) => state.isOwner || getPlayerPermissionValue(state.playerPermissions, item.key)
  );

  const selectedRoleEnabledCount = permissionList.filter((item) => permissionFlags[item.key]).length;

  const handleResponse = useCallback(
    (response?: NuiResponse) => {
      if (!response) return;

      if (response.success && response.data) {
        dispatch(setBenchPermissions(response.data));
        setDeletePending(false);
        setErrorMessage(null);
      } else if (response.error) {
        setErrorMessage(
          ((Locale as Record<string, string>)[response.error] as string)
            || response.error
            || L('crafting_no_permission', 'You do not have permission')
        );
      } else {
        setErrorMessage(L('crafting_no_permission', 'You do not have permission'));
      }
    },
    [L, dispatch]
  );

  const sendAction = useCallback(
    async (event: string, payload: Record<string, unknown>) => {
      try {
        setErrorMessage(null);
        const response = await fetchNui<NuiResponse>(event, payload);
        handleResponse(response);
      } catch (error) {
        setErrorMessage(L('crafting_no_permission', 'You do not have permission'));
      }
    },
    [L, handleResponse]
  );

  const handleSaveRole = useCallback(() => {
    if (!state.benchId || selectedRoleId == null) return;

    sendAction('benchPermissions:updateRole', {
      benchId: state.benchId,
      roleId: selectedRoleId,
      name: roleName.trim() || selectedRole?.name || L('crafting_role_new', 'New role'),
      permissions: {
        use: permissionFlags.use,
        move: permissionFlags.move,
        pack: permissionFlags.pack,
        manage: permissionFlags.manage,
      },
    });
  }, [L, permissionFlags, roleName, selectedRole?.name, selectedRoleId, sendAction, state.benchId]);

  const handleDeleteRole = useCallback(() => {
    if (!state.benchId || selectedRoleId == null || !selectedRole) return;

    if (selectedRole.memberCount > 0) {
      setErrorMessage(L('crafting_role_has_members', 'Role has members'));
      setDeletePending(false);
      return;
    }

    if (!deletePending) {
      setDeletePending(true);
      setErrorMessage(L('crafting_permissions_confirm_delete', 'Delete this role?'));
      return;
    }

    sendAction('benchPermissions:deleteRole', {
      benchId: state.benchId,
      roleId: selectedRoleId,
    });
    setDeletePending(false);
  }, [L, deletePending, selectedRole, selectedRoleId, sendAction, state.benchId]);

  const handleCancelDelete = useCallback(() => {
    setDeletePending(false);
    setErrorMessage(null);
  }, []);

  const handleCreateRole = useCallback(() => {
    if (!state.benchId) return;

    sendAction('benchPermissions:createRole', {
      benchId: state.benchId,
      name: L('crafting_role_new', 'New role'),
      permissions: defaultPermissions,
    });
  }, [L, sendAction, state.benchId]);

  const handleAddMember = useCallback(() => {
    if (!state.benchId || selectedRoleId == null) return;

    const target = (selectedOnlinePlayer || newMemberIdentifier).trim();
    if (!target) {
      setErrorMessage(L('crafting_permissions_identifier_required', 'Identifier required'));
      return;
    }

    sendAction('benchPermissions:setMemberRole', {
      benchId: state.benchId,
      roleId: selectedRoleId,
      target,
    });
    setNewMemberIdentifier('');
    setSelectedOnlinePlayer('');
  }, [L, newMemberIdentifier, selectedOnlinePlayer, selectedRoleId, sendAction, state.benchId]);

  const handleRemoveMember = useCallback(
    (identifier: string) => {
      if (!state.benchId) return;

      sendAction('benchPermissions:setMemberRole', {
        benchId: state.benchId,
        target: identifier,
      });
    },
    [sendAction, state.benchId]
  );

  const handleTransferOwnership = useCallback(() => {
    if (!state.benchId) return;

    const target = transferTarget.trim();
    if (!target) {
      setErrorMessage(L('crafting_permissions_identifier_required', 'Identifier required'));
      return;
    }

    sendAction('benchPermissions:transferOwnership', {
      benchId: state.benchId,
      target,
    });
    setTransferTarget('');
  }, [L, sendAction, state.benchId, transferTarget]);

  if (!state.open) {
    return null;
  }

  const identityLabel = state.isOwner
    ? L('crafting_permissions_owner', 'Owner')
    : state.playerPermissions?.roleName || L('crafting_role_member', 'Member');

  return (
    <div className={`bench-permissions-overlay${isLoadout ? ' bench-permissions-overlay--loadout' : ''}`}>
      <div
        className={`bench-permissions-modal bench-permissions-modal--prp${isLoadout ? ` bench-permissions-modal--loadout ${isStorage ? 'is-storage' : 'is-bench'}` : ''}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="bench-permissions-title"
      >
        <header className="bench-prp-header">
          <div className="bench-prp-header-main">
            <span className="bench-prp-header-icon" aria-hidden="true">
              <img src={othersIcon} alt="" />
              <i className={`fa-solid ${isStorage ? 'fa-box-archive' : 'fa-screwdriver-wrench'}`} />
            </span>

            <div className="bench-prp-header-copy">
              <p className="bench-prp-header-label">{state.benchLabel || state.benchId}</p>
              <h2 id="bench-permissions-title">{isStorage ? L('storage_permissions_title', 'Storage Permissions') : L('crafting_permissions_title', 'Bench Permissions')}</h2>

              <div className="bench-prp-header-meta">
                <span className="bench-meta-chip">{state.benchId}</span>
                <span className="bench-meta-chip">
                  {L('crafting_permissions_owner', 'Owner')}: {state.owner?.name || L('crafting_permissions_unknown', 'Unknown')}
                </span>
                {state.owner?.serverId != null && <span className="bench-meta-chip">ID {state.owner.serverId}</span>}
                <span className={`bench-status-pill ${state.owner?.online ? 'is-online' : 'is-offline'}`}>
                  {state.owner?.online
                    ? L('crafting_permissions_status_online', 'Online')
                    : L('crafting_permissions_status_offline', 'Offline')}
                </span>
              </div>

              <div className="bench-prp-access-row">
                <span className={`bench-status-pill ${state.isOwner ? 'is-owner' : 'is-linked'}`}>{identityLabel}</span>
                {currentUserAccess.map((item) => (
                  <span key={item.key} className="bench-access-chip is-active">
                    {item.label}
                  </span>
                ))}
              </div>
            </div>
          </div>

          <button
            type="button"
            className="bench-prp-close"
            aria-label={L('crafting_permissions_close', 'Close')}
            onClick={closeModal}
          >
            <i className="fas fa-times" />
          </button>
        </header>

        {errorMessage && <div className="bench-permissions-error">{errorMessage}</div>}

        <div className="bench-prp-body">
          <aside className="bench-prp-sidebar">
            <section className="bench-prp-sidebar-section">
              <div className="bench-prp-sidebar-head">
                <div>
                  <p className="bench-prp-sidebar-label">{L('crafting_permissions_roles', 'Roles')}</p>
                  <h3>{state.roles.length}</h3>
                </div>

                {canManageRoles && (
                  <button
                    type="button"
                    className="bench-permissions-button bench-permissions-button--accent bench-prp-inline-action"
                    onClick={handleCreateRole}
                  >
                    <i className="fa-solid fa-plus" aria-hidden="true" />
                    {L('crafting_permissions_add_role', 'Create role')}
                  </button>
                )}
              </div>

              <div className="bench-prp-role-list">
                {state.roles.map((role) => (
                  <button
                    key={role.id}
                    type="button"
                    onClick={() => setSelectedRoleId(role.id)}
                    className={`bench-prp-role-item ${role.id === selectedRoleId ? 'is-active' : ''}`}
                  >
                    <span className="bench-prp-role-icon" aria-hidden="true">
                      <i className="fa-solid fa-user-shield" />
                    </span>
                    <div className="bench-prp-role-item-main">
                      <strong>{role.name}</strong>
                      <span>{formatMembersCount(role.memberCount)}</span>
                    </div>
                    <div className="bench-prp-role-item-meta">
                      <span>{permissionList.filter((item) => getRolePermissionValue(role, item.key)).length} permissions</span>
                      <i className="fas fa-chevron-right" />
                    </div>
                  </button>
                ))}

                {state.roles.length === 0 && (
                  <div className="bench-prp-empty-note">
                    {L('crafting_permissions_no_roles', 'No roles')}
                  </div>
                )}
              </div>
            </section>

            <section className="bench-prp-sidebar-section bench-prp-sidebar-section--fill">
              <div className="bench-prp-sidebar-head">
                <div>
                  <p className="bench-prp-sidebar-label">{L('crafting_permissions_members', 'Members')}</p>
                  <h3>{totalMembers + (state.owner ? 1 : 0)}</h3>
                </div>

                <span className="bench-prp-sidebar-caption">
                  {selectableOnlinePlayers.length} {L('crafting_permissions_online', 'Online players')}
                </span>
              </div>

              <div className="bench-prp-roster-list">
                {state.owner && (
                  <div className="bench-prp-roster-card bench-prp-roster-card--owner">
                    <span className="bench-prp-avatar" aria-hidden="true">{getInitials(state.owner.name)}</span>
                    <div className="bench-prp-roster-copy">
                      <strong>{state.owner.name}</strong>
                      <span>{state.owner.identifier}</span>
                    </div>
                    <div className="bench-prp-roster-meta">
                      <span className="bench-status-pill is-owner">{L('crafting_permissions_owner', 'Owner')}</span>
                    </div>
                  </div>
                )}

                {allRoleMembers.map((member) => (
                  <div key={member.identifier} className="bench-prp-roster-card">
                    <span className="bench-prp-avatar" aria-hidden="true">{getInitials(member.name)}</span>
                    <div className="bench-prp-roster-copy">
                      <strong>{member.name}</strong>
                      <span>{member.identifier}</span>
                    </div>
                    <div className="bench-prp-roster-meta">
                      <span className="bench-meta-chip">{member.roleName}</span>
                    </div>
                  </div>
                ))}

                {!state.owner && allRoleMembers.length === 0 && (
                  <div className="bench-prp-empty-note">
                    {L('crafting_permissions_no_members', 'No members')}
                  </div>
                )}
              </div>
            </section>
          </aside>

          <section className="bench-prp-stage">
            {selectedRole ? (
              <>
                <div className="bench-prp-stage-head">
                  <div>
                    <h3>{selectedRole.name}</h3>
                    <p>{L('crafting_permissions_role_summary', 'Configure permissions and members for this role.')}</p>
                  </div>

                  <div className="bench-prp-stage-summary">
                    <span className="bench-meta-chip">{formatMembersCount(selectedRole.memberCount)}</span>
                    <span className="bench-meta-chip">
                      {selectedRoleEnabledCount}/{permissionList.length} {L('crafting_permissions_active', 'active')}
                    </span>
                  </div>
                </div>

                <section className="bench-prp-panel">
                  <div className="bench-prp-panel-head">
                    <div>
                      <p className="bench-prp-sidebar-label">{L('crafting_permissions_role_name', 'Role settings')}</p>
                      <h4>{L('crafting_permissions_role_name', 'Role name')}</h4>
                    </div>
                  </div>

                  <label className="bench-prp-field">
                    <span>{L('crafting_permissions_role_name', 'Role name')}</span>
                    <input
                      className="bench-prp-input"
                      type="text"
                      value={roleName}
                      disabled={!canManageRoles}
                      onChange={(event) => setRoleName(event.target.value)}
                    />
                  </label>

                  <div className="bench-prp-permission-list">
                    {permissionList.map((item) => {
                      const enabled = permissionFlags[item.key];

                      return (
                        <div key={item.key} className="bench-prp-permission-row">
                          <span className="bench-prp-permission-icon" aria-hidden="true">
                            <i className={`fa-solid ${item.icon}`} />
                          </span>
                          <div className="bench-prp-permission-copy">
                            <strong>{item.label}</strong>
                            <span>{item.description}</span>
                          </div>

                          {canManageRoles ? (
                            <button
                              type="button"
                              className={`bench-prp-toggle ${enabled ? 'is-enabled' : ''}`}
                              onClick={() =>
                                setPermissionFlags((prev) => ({ ...prev, [item.key]: !prev[item.key] }))
                              }
                            >
                              <span />
                            </button>
                          ) : (
                            <span className={`bench-prp-state-badge ${enabled ? 'is-enabled' : ''}`}>
                              {enabled ? L('enabled', 'Allowed') : L('disabled', 'Denied')}
                            </span>
                          )}
                        </div>
                      );
                    })}
                  </div>

                  <div className="bench-prp-role-actions">
                    <button
                      type="button"
                      className="bench-permissions-button bench-permissions-button--accent"
                      disabled={!canManageRoles}
                      onClick={handleSaveRole}
                    >
                      <i className="fa-solid fa-floppy-disk" aria-hidden="true" />
                      {L('crafting_permissions_save_role', 'Save changes')}
                    </button>

                    {canManageRoles && (
                      <button
                        type="button"
                        className={`bench-permissions-button bench-permissions-button--danger ${deletePending ? 'is-confirm' : ''}`}
                        disabled={selectedRole.memberCount > 0}
                        onClick={handleDeleteRole}
                      >
                        <i className="fa-solid fa-trash-can" aria-hidden="true" />
                        {deletePending
                          ? L('crafting_permissions_confirm_delete', 'Confirm delete')
                          : L('crafting_permissions_delete_role', 'Delete role')}
                      </button>
                    )}

                    {deletePending && (
                      <button
                        type="button"
                        className="bench-permissions-button bench-permissions-button--ghost"
                        onClick={handleCancelDelete}
                      >
                        {L('crafting_permissions_close', 'Cancel')}
                      </button>
                    )}
                  </div>
                </section>

                <section className="bench-prp-panel">
                  <div className="bench-prp-panel-head">
                    <div>
                      <p className="bench-prp-sidebar-label">{L('crafting_permissions_members', 'Assigned members')}</p>
                      <h4>{formatMembersCount(selectedRole.memberCount)}</h4>
                    </div>
                  </div>

                  {selectedRole.members.length === 0 ? (
                    <div className="bench-prp-empty-panel">
                      {L('crafting_permissions_no_members', 'No members assigned to this role.')}
                    </div>
                  ) : (
                    <div className="bench-prp-members-list">
                      {selectedRole.members.map((member) => (
                        <div key={member.identifier} className="bench-prp-member-card">
                          <span className="bench-prp-avatar" aria-hidden="true">{getInitials(member.name)}</span>
                          <div className="bench-prp-member-copy">
                            <div className="bench-prp-member-title-row">
                              <strong>{member.name}</strong>
                              {member.serverId != null && <span className="bench-meta-chip">ID {member.serverId}</span>}
                            </div>
                            <span>{member.identifier}</span>
                            {member.addedBy && <small>{member.addedBy}</small>}
                          </div>

                          <div className="bench-prp-member-actions">
                            <span className={`bench-status-pill ${member.online ? 'is-online' : 'is-offline'}`}>
                              {member.online
                                ? L('crafting_permissions_status_online', 'Online')
                                : L('crafting_permissions_status_offline', 'Offline')}
                            </span>
                            {canManageRoles && (
                              <button
                                type="button"
                                className="bench-permissions-button bench-permissions-button--ghost bench-permissions-button--compact"
                                onClick={() => handleRemoveMember(member.identifier)}
                              >
                                <i className="fa-solid fa-user-minus" aria-hidden="true" />
                                {L('crafting_permissions_remove', 'Remove')}
                              </button>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  <div className="bench-prp-builder">
                    <div className="bench-prp-panel-head bench-prp-panel-head--tight">
                      <div>
                        <p className="bench-prp-sidebar-label">{L('crafting_permissions_add_member', 'Add member')}</p>
                        <h4>{L('crafting_permissions_assign', 'Assign member')}</h4>
                      </div>
                    </div>

                    <div className="bench-prp-builder-grid">
                      <PlayerSelect
                        value={selectedOnlinePlayer}
                        disabled={!canManageRoles}
                        placeholder={L('crafting_permissions_select_player', 'Select player')}
                        options={selectableOnlinePlayers.map((player: OnlinePlayer) => ({
                          value: player.identifier,
                          label: `${player.name}${player.serverId != null ? ` (${player.serverId})` : ''}${
                            player.roleId ? ` - ${L('crafting_permissions_assigned', 'assigned')}` : ''
                          }`,
                        }))}
                        onChange={(value) => {
                          setSelectedOnlinePlayer(value);
                          setNewMemberIdentifier(value);
                        }}
                      />

                      <input
                        className="bench-prp-input"
                        type="text"
                        value={newMemberIdentifier}
                        disabled={!canManageRoles}
                        placeholder={L('crafting_permissions_identifier', 'Identifier')}
                        onChange={(event) => setNewMemberIdentifier(event.target.value)}
                      />
                    </div>

                    <button
                      type="button"
                      className="bench-permissions-button bench-permissions-button--accent"
                      disabled={!canManageRoles}
                      onClick={handleAddMember}
                    >
                      <i className="fa-solid fa-user-plus" aria-hidden="true" />
                      {L('crafting_permissions_assign', 'Assign')}
                    </button>
                  </div>
                </section>

                <section className="bench-prp-panel bench-prp-transfer-panel">
                  <div className="bench-prp-panel-head">
                    <div>
                      <p className="bench-prp-sidebar-label">{L('crafting_permissions_transfer', 'Transfer ownership')}</p>
                      <h4>{L('crafting_permissions_transfer_button', 'Transfer')}</h4>
                    </div>
                    {!state.canTransfer && <span className="bench-meta-chip">{L('crafting_permissions_owner', 'Owner')}</span>}
                  </div>

                  <div className="bench-prp-transfer-row">
                    <input
                      className="bench-prp-input"
                      type="text"
                      value={transferTarget}
                      placeholder={L('crafting_permissions_identifier', 'Identifier')}
                      onChange={(event) => setTransferTarget(event.target.value)}
                    />
                    <button
                      type="button"
                      className="bench-permissions-button bench-permissions-button--accent"
                      disabled={!state.canTransfer}
                      onClick={handleTransferOwnership}
                    >
                      <i className="fa-solid fa-arrow-right-arrow-left" aria-hidden="true" />
                      {L('crafting_permissions_transfer_button', 'Transfer')}
                    </button>
                  </div>
                </section>
              </>
            ) : (
              <div className="bench-prp-empty-panel bench-prp-empty-panel--full">
                <strong>{L('crafting_permissions_no_role_selected', 'No role selected')}</strong>
                <span>{L('crafting_permissions_select_role', 'Select a role to manage permissions')}</span>
              </div>
            )}
          </section>
        </div>
      </div>
    </div>
  );
};

export default BenchPermissionsModal;
