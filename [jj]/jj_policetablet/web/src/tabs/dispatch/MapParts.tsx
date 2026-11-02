import {
  ActionIcon,
  Badge,
  Box,
  Button,
  Checkbox,
  Flex,
  Group,
  Paper,
  Stack,
  Text,
  Tooltip,
} from '@mantine/core';
import { FaCompass, FaMinus, FaPlus } from 'react-icons/fa';
import { IconK5 } from '../../icons';
import { openEntityTab } from '../../utils/nui';

export function MapTiles({ offsetX, offsetY, zoom, dimensions, tileSize }: any) {
  const s = Math.min(zoom, 5);
  const i = Math.pow(2, zoom - s);
  const a = tileSize * i;
  const u = Math.pow(2, s);
  const f = Math.max(0, Math.floor(-offsetX / a));
  const h = Math.max(0, Math.floor(-offsetY / a));
  const p = Math.min(u - 1, Math.floor((dimensions.width - offsetX) / a));
  const g = Math.min(u - 1, Math.floor((dimensions.height - offsetY) / a));
  const v = [];
  for (let ty = h; ty <= g; ty++) {
    for (let tx = f; tx <= p; tx++) {
      v.push({
        tx,
        ty,
      });
    }
  }
  return (
    <Box
      pos="absolute"
      style={{
        transform: `translate3d(${offsetX}px, ${offsetY}px, 0)`,
        pointerEvents: 'none',
      }}
    >
      {v.map(({ tx, ty }: any) => (
        <img
          key={`${s}_${tx}_${ty}`}
          src={`map/tiles/${s}/${tx}/${ty}.png`}
          alt=""
          style={{
            position: 'absolute',
            left: tx * a,
            top: ty * a,
            width: a + 1.5,
            height: a + 1.5,
            pointerEvents: 'none',
          }}
        />
      ))}
    </Box>
  );
}

export function AgentMarker({
  agent,
  pixel,
  offsetX,
  offsetY,
  isSelected,
  onSelect,
  onDeselect,
  loadingDetails,
  details,
  onWaypoint,
}: any) {
  const h = agent.department?.toLowerCase() || 'saed';
  const p = h === 'lssd';
  const g = h === 'lspd';
  const v = h === 'saed';
  let y = '#228be6';
  let backgroundColor = 'rgba(34, 139, 230, 0.2)';
  let S = 'pulse-blue';
  if (agent.is_self) {
    y = '#fd7e14';
    backgroundColor = 'rgba(253, 126, 20, 0.2)';
    S = 'pulse-orange';
  } else {
    if (p) {
      y = '#a855f7';
      backgroundColor = 'rgba(168,85,247, 0.2)';
      S = 'pulse-gold';
    } else {
      if (v) {
        y = '#e03131';
        backgroundColor = 'rgba(224, 49, 49, 0.2)';
        S = 'pulse-red';
      }
    }
  }
  let backgroundColor2 = '#212529';
  let j = '#228be6';
  if (agent.is_self) {
    backgroundColor2 = '#e8590c';
    j = '#ff922b';
  } else {
    if (p) {
      backgroundColor2 = '#3b1a5a';
      j = '#a855f7';
    } else {
      if (g) {
        backgroundColor2 = '#0f2b46';
        j = '#228be6';
      } else {
        backgroundColor2 = '#4c1111';
        j = '#e03131';
      }
    }
  }
  return (
    <div
      style={{
        position: 'absolute',
        left: offsetX + pixel.x,
        top: offsetY + pixel.y,
        transform: 'translate(-50%, -50%)',
        pointerEvents: 'auto',
        zIndex: isSelected ? 100 : 10,
      }}
    >
      <Tooltip
        label={
          <Text size="xs" fw={700}>
            {agent.asig}
          </Text>
        }
        position="top"
        withArrow
        arrowSize={6}
        color="dark"
      >
        <Box
          onClick={(event) => {
            event.stopPropagation();
            if (isSelected) {
              onDeselect();
            } else {
              onSelect();
            }
          }}
          style={{
            cursor: 'pointer',
            position: 'relative',
          }}
        >
          {agent.is_self && (
            <Box
              pos="absolute"
              w={32}
              h={32}
              top={-6}
              left={-6}
              style={{
                borderRadius: '50%',
                backgroundColor,
                border: `1.5px solid ${y}`,
                animation: `${S} 2s infinite ease-in-out`,
                pointerEvents: 'none',
              }}
            />
          )}
          <Flex
            align="center"
            justify="center"
            style={{
              width: '20px',
              height: '20px',
              borderRadius: '50%',
              backgroundColor: backgroundColor2,
              border: `1.5px solid ${j}`,
              boxShadow: '0 2px 4px rgba(0, 0, 0, 0.4)',
              position: 'relative',
              transition: 'transform 0.15s ease, background-color 0.3s ease, border-color 0.3s ease',
            }}
          />
        </Box>
      </Tooltip>
      {isSelected && (
        <Paper
          pos="absolute"
          top={28}
          left={-100}
          w={200}
          p="xs"
          radius="md"
          style={{
            backgroundColor: 'rgba(26, 27, 30, 0.95)',
            border: '1px solid var(--border-color)',
            zIndex: 110,
            boxShadow: '0 10px 15px rgba(0, 0, 0, 0.5)',
            pointerEvents: 'auto',
          }}
          onClick={(event) => event.stopPropagation()}
        >
          <Box
            style={{
              position: 'absolute',
              top: '-7px',
              left: '50%',
              transform: 'translateX(-50%)',
              width: 0,
              height: 0,
              borderLeft: '7px solid transparent',
              borderRight: '7px solid transparent',
              borderBottom: '7px solid var(--border-color)',
              pointerEvents: 'none',
            }}
          />
          <Box
            style={{
              position: 'absolute',
              top: '-6px',
              left: '50%',
              transform: 'translateX(-50%)',
              width: 0,
              height: 0,
              borderLeft: '6px solid transparent',
              borderRight: '6px solid transparent',
              borderBottom: '6px solid rgba(26, 27, 30, 0.95)',
              pointerEvents: 'none',
            }}
          />
          {loadingDetails ? (
            <Text size="xs" c="dimmed" ta="center" py="xs">
              Cargando detalles...
            </Text>
          ) : details && details.citizen ? (
            <Stack gap="xs">
              <Group justify="space-between" align="flex-start" wrap="nowrap">
                <Box
                  style={{
                    flex: 1,
                  }}
                >
                  <Group gap={6} align="center" wrap="nowrap">
                    <Text
                      size="sm"
                      fw={700}
                      truncate
                      c="white"
                      style={{
                        maxWidth: '120px',
                      }}
                    >
                      {details.citizen.firstname} {details.citizen.lastname}
                    </Text>
                    <Badge
                      size="xs"
                      color={
                        details.department?.toLowerCase() === 'lssd'
                          ? 'yellow'
                          : details.department?.toLowerCase() === 'lspd'
                            ? 'blue'
                            : 'red'
                      }
                      variant="filled"
                      style={{
                        textTransform: 'uppercase',
                        fontSize: '9px',
                        height: '16px',
                        padding: '0 4px',
                      }}
                    >
                      {details.department || 'N/A'}
                    </Badge>
                  </Group>
                  <Text size="xs" c="dimmed">
                    {details.rank_label}
                    {' ('}
                    {details.badge_number})
                  </Text>
                </Box>
              </Group>
              {details.divisions?.length > 0 && (
                <Group gap={4}>
                  {details.divisions.map((division) => (
                    <Badge key={division} size="xs" color="gray">
                      {division}
                    </Badge>
                  ))}
                </Group>
              )}
              <Group gap="xs" grow>
                <Button
                  size="xs"
                  leftSection={<IconK5 size={12} />}
                  color="blue"
                  onClick={() => onWaypoint(agent)}
                >
                  GPS
                </Button>
                <Button
                  size="xs"
                  variant="default"
                  onClick={() => {
                    onDeselect();
                    openEntityTab({
                      type: 'citizen',
                      citizenId: details.citizen.citizenid,
                    });
                  }}
                >
                  Ficha
                </Button>
              </Group>
            </Stack>
          ) : (
            <Text size="xs" c="dimmed" ta="center" py="xs">
              Error al cargar detalles
            </Text>
          )}
        </Paper>
      )}
    </div>
  );
}

export function MapZoomControls({ onZoomIn, onZoomOut, onCenter }: any) {
  return (
    <Stack
      pos="absolute"
      top={16}
      right={16}
      gap="xs"
      style={{
        zIndex: 120,
        pointerEvents: 'auto',
      }}
    >
      <Paper
        p={6}
        radius="md"
        shadow="md"
        style={{
          backgroundColor: 'rgba(26, 27, 30, 0.85)',
          border: '1px solid var(--border-color)',
        }}
      >
        <Stack gap={4}>
          <ActionIcon size="lg" variant="subtle" color="gray" onClick={onZoomIn} title="Acercar">
            <FaPlus />
          </ActionIcon>
          <ActionIcon size="lg" variant="subtle" color="gray" onClick={onZoomOut} title="Alejar">
            <FaMinus />
          </ActionIcon>
          <ActionIcon size="lg" variant="subtle" color="gray" onClick={onCenter} title="Centrar mapa">
            <FaCompass />
          </ActionIcon>
        </Stack>
      </Paper>
    </Stack>
  );
}

export function DepartmentFilter({ visibleDepartments, onChange }: any) {
  return (
    <Paper
      pos="absolute"
      top={16}
      left={16}
      p="xs"
      radius="md"
      shadow="md"
      style={{
        backgroundColor: 'rgba(26, 27, 30, 0.85)',
        border: '1px solid var(--border-color)',
        zIndex: 120,
        pointerEvents: 'auto',
        minWidth: '110px',
      }}
    >
      <Stack gap="xs">
        <Text size="xs" fw={700} c="dimmed" tt="uppercase" lts={0.5}>
          Filtros
        </Text>
        <Checkbox
          label="LSPD"
          color="blue"
          checked={visibleDepartments.lspd}
          onChange={(event) => onChange('lspd', event.currentTarget.checked)}
          styles={{
            label: {
              fontSize: '12px',
              fontWeight: 600,
              color: '#fff',
              cursor: 'pointer',
            },
            input: {
              cursor: 'pointer',
            },
          }}
        />
        <Checkbox
          label="LSSD"
          color="yellow"
          checked={visibleDepartments.lssd}
          onChange={(event) => onChange('lssd', event.currentTarget.checked)}
          styles={{
            label: {
              fontSize: '12px',
              fontWeight: 600,
              color: '#fff',
              cursor: 'pointer',
            },
            input: {
              cursor: 'pointer',
            },
          }}
        />
        <Checkbox
          label="SAED"
          color="red"
          checked={visibleDepartments.saed}
          onChange={(event) => onChange('saed', event.currentTarget.checked)}
          styles={{
            label: {
              fontSize: '12px',
              fontWeight: 600,
              color: '#fff',
              cursor: 'pointer',
            },
            input: {
              cursor: 'pointer',
            },
          }}
        />
      </Stack>
    </Paper>
  );
}
