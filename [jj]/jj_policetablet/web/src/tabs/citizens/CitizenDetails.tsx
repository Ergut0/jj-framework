import { Badge, Grid } from '@mantine/core';
import { useDisclosure } from '@mantine/hooks';
import { FaBox, FaCarAlt, FaFileInvoice } from 'react-icons/fa';
import { FaNoteSticky } from 'react-icons/fa6';
import { usePermissions } from '../../state/atoms';
import { fetchNui } from '../../utils/nui';
import { AddBillsModal } from './AddBillsModal';
import { AddCitizenNoteModal } from './AddCitizenNoteModal';
import {
  CitizenBills,
  CitizenIncidents,
  CitizenNotes,
  CitizenVehicles,
  InfoSection,
} from './CitizenSections';

export const CitizenDetails = ({ selectedCitizen, setSelectedCitizen }: any) => {
  const [opened, r] = useDisclosure(false);
  const [opened2, s] = useDisclosure(false);
  const { haveRankPerms } = usePermissions();
  const a = () => {
    if (!selectedCitizen?.notes) {
      return [];
    }
    const b = selectedCitizen.notes.filter((note) => note.pinged);
    const S = selectedCitizen.notes.filter((note) => !note.pinged);
    return [...b, ...S];
  };
  const handleTogglePinged = async (b) => {
    if (!selectedCitizen) {
      return;
    }
    const notes = selectedCitizen.notes?.map((w) =>
      w.id === b
        ? {
            ...w,
            pinged: !w.pinged,
          }
        : w,
    );
    setSelectedCitizen({
      ...selectedCitizen,
      notes,
    });
    await fetchNui('togglePingedStatus', {
      citizenid: selectedCitizen.citizenid,
      noteId: b,
    });
  };
  const handleAddNote = async (b, S) => {
    if (!selectedCitizen) {
      return;
    }
    const w: any = {
      id: selectedCitizen.notes ? selectedCitizen.notes.length + 1 : 1,
      citizenid: selectedCitizen.citizenid,
      title: b,
      description: S,
      pinged: false,
      date: new Date().toLocaleDateString(),
      author: 'Current Officer',
    };
    const response = await fetchNui('addCitizenNote', w);
    w.id = response.id;
    w.date = response.date;
    w.author = response.author;
    const notes = selectedCitizen.notes ? [...selectedCitizen.notes, w] : [w];
    setSelectedCitizen({
      ...selectedCitizen,
      notes,
    });
  };
  const handleDeleteNote = async (b) => {
    if (!selectedCitizen) {
      return;
    }
    await fetchNui('deleteCitizenNote', {
      citizenid: selectedCitizen.citizenid,
      noteId: b,
    });
    const notes = selectedCitizen.notes?.filter((w) => w.id !== b);
    setSelectedCitizen({
      ...selectedCitizen,
      notes,
    });
  };
  const p = () =>
    selectedCitizen?.bills
      ? selectedCitizen.bills.reduce((total, bill) => (bill.payed ? total : total + bill.amount), 0)
      : 0;
  const handleAddBills = async (b) => {
    if (!selectedCitizen) {
      return;
    }
    const response = await fetchNui('addCitizenBills', {
      citizenid: selectedCitizen.citizenid,
      bills: b,
    });
    const bills = selectedCitizen.bills ? [...selectedCitizen.bills, ...response] : response;
    setSelectedCitizen({
      ...selectedCitizen,
      bills,
    });
  };
  const handleDeleteBill = async (b) => {
    if (!selectedCitizen) {
      return;
    }
    await fetchNui('deleteCitizenBill', {
      billId: b,
    });
    const bills = selectedCitizen.bills?.filter((w) => w.id !== b);
    setSelectedCitizen({
      ...selectedCitizen,
      bills,
    });
  };
  const y = selectedCitizen?.bills?.filter((b) => !b.payed).reduce((b, S) => b + S.amount, 0) || 0;
  return (
    <>
      <Grid mt={20} justify="space-between" mx={8}>
        <InfoSection title="Notas" icon={FaNoteSticky} onAdd={r.open}>
          <CitizenNotes
            notes={a()}
            onDeleteNote={handleDeleteNote}
            canDelete={haveRankPerms(['citizen.notes.delete'])}
            onTogglePinged={handleTogglePinged}
          />
          {opened && (
            <AddCitizenNoteModal
              opened={opened}
              onClose={r.close}
              citizen={selectedCitizen}
              onAddNote={handleAddNote}
            />
          )}
        </InfoSection>
        <InfoSection
          title={`Multas ($${y})`}
          icon={FaFileInvoice}
          onAdd={s.open}
          rightSection={
            selectedCitizen?.bills && p() > 7e4 ? (
              <Badge color="red" variant="light" radius="sm">
                Cantidad monetaria superada
              </Badge>
            ) : null
          }
        >
          <CitizenBills
            bills={selectedCitizen?.bills || []}
            canDelete={haveRankPerms(['citizen.bills.delete'])}
            onDeleteBill={handleDeleteBill}
          />
          <AddBillsModal
            opened={opened2}
            onClose={s.close}
            selectedCitizen={selectedCitizen}
            setSelectedCitizen={setSelectedCitizen}
            onAddBills={handleAddBills}
          />
        </InfoSection>
        <InfoSection title="Vehículos" icon={FaCarAlt} onAdd={false}>
          <CitizenVehicles vehicles={selectedCitizen?.vehicles || []} />
        </InfoSection>
        <InfoSection title="Incidentes" icon={FaBox} onAdd={false}>
          <CitizenIncidents incidents={selectedCitizen?.incidents || []} />
        </InfoSection>
      </Grid>
    </>
  );
};
