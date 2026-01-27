import express, { Request, Response } from 'express';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

interface HealthResponse {
  status: string;
  timestamp: string;
}

app.get('/health', (_req: Request, res: Response<HealthResponse>) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

interface Item {
  id: number;
  name: string;
  price: number;
}

const items: Item[] = [
  { id: 1, name: 'Widget', price: 9.99 },
  { id: 2, name: 'Gadget', price: 19.99 }
];

app.get('/api/items', (_req: Request, res: Response<Item[]>) => {
  res.json(items);
});

app.get('/api/items/:id', (req: Request, res: Response<Item | { error: string }>) => {
  const id = parseInt(req.params.id, 10);
  const item = items.find(i => i.id === id);

  if (!item) {
    res.status(404).json({ error: 'Item not found' });
    return;
  }

  res.json(item);
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

export { app };
