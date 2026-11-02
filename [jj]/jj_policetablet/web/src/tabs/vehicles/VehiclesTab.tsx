import { Group } from '@mantine/core';
import { useEffect, useState } from 'react';
import { mockVehicles } from '../../data/mockCitizens';
import { fetchNui, isBrowser } from '../../utils/nui';
import { CitizenListEmpty } from '../citizens/CitizensTab';
import { VehicleHeader } from './VehicleDetails';
import { VehicleList } from './VehicleList';

export function VehiclesTab({ initialVehiclePlate }: any) {
  const [vehicle, setVehicle] = useState<any>(null);
  const [vehicles, setVehicles] = useState<any>(isBrowser() ? mockVehicles : []);
  useEffect(() => {
    if (isBrowser()) {
      return;
    }
    (async () => {
      const response = await fetchNui('getVehicles', {});
      setVehicles(response);
    })();
  }, []);
  useEffect(() => {
    if (!initialVehiclePlate) {
      return;
    }
    (async () => {
      const response = await fetchNui('getVehicleByPlate', {
        plate: initialVehiclePlate,
      });
      setVehicle(response);
    })();
  }, [initialVehiclePlate]);
  const handleSelectVehicle = async (i) => {
    if (isBrowser()) {
      setVehicle(i);
      return;
    }
    const response = await fetchNui('getVehicleByPlate', {
      plate: i.plate,
    });
    setVehicle(response);
  };
  return vehicles ? (
    <>
      <Group flex={1} justify="flex-start" align="flex-start" gap={0}>
        <VehicleList
          onSelectVehicle={handleSelectVehicle}
          vehicles={vehicles}
          onSelectVehicles={setVehicles}
        />
        <VehicleHeader vehicle={vehicle} setSelectedVehicle={setVehicle} />
      </Group>
    </>
  ) : (
    <CitizenListEmpty />
  );
}
