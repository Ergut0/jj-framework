import { mockVehicles } from './mockCitizens';

export const mockIncidents = [
  {
    id: 1,
    title: 'Robo en tienda de conveniencia xawd axwdawd a',
    description: 'Un individuo ingresó a la tienda y sustrajo varios productos sin pagar.',
    creator: {
      name: 'Aohn Doe',
      citizenid: '12345678',
    },
    date: '2024-06-01',
    status: 'Abierto',
    vehicles: [mockVehicles[0], mockVehicles[1]],
  },
  {
    id: 2,
    title: 'Accidente de tráfico',
    description:
      '<h2 style="text-align: center;">Welcome to Mantine rich text editor</h2><p><code>RichTextEditor</code> component focuses on usability and is designed to be as simple as possible to bring a familiar editing experience to regular users. <code>RichTextEditor</code> is based on <a href="https://tiptap.dev/" rel="noopener noreferrer" target="_blank">Tiptap.dev</a> and supports all of its features:</p><ul><li>General text formatting: <strong>bold</strong>, <em>italic</em>, <u>underline</u>, <s>strike-through</s> </li><li>Headings (h1-h6)</li><li>Sub and super scripts (<sup>&lt;sup /&gt;</sup> and <sub>&lt;sub /&gt;</sub> tags)</li><li>Ordered and bullet lists</li><li>Text align&nbsp;</li><li>And all <a href="https://tiptap.dev/extensions" target="_blank" rel="noopener noreferrer">other extensions</a></li></ul>',
    creator: {
      name: 'Jane Smith',
      citizenid: '87654321',
    },
    date: '2024-06-02',
    status: 'Cerrado',
    vehicles: [mockVehicles[2]],
  },
  {
    id: 345,
    title: 'Vandalismo en parque',
    description: 'Se reportó grafiti en las paredes del parque central.',
    creator: {
      name: 'Alice Johnson',
      citizenid: '11223344',
    },
    date: '2024-06-03',
    status: 'Cerrado',
    vehicles: [mockVehicles[3]],
  },
  {
    id: 512,
    title: 'Persecución en autopista',
    description: 'Seguimiento de vehículo sospechoso por exceso de velocidad.',
    creator: {
      name: 'Aob Brown',
      citizenid: '44332211',
    },
    date: '2024-06-06',
    status: 'Abierto',
    vehicles: [mockVehicles[0]],
  },
];
