import { Router } from "express";
import { deleteBlob } from "../controllers/storageController";

const router = Router();

// DELETE /api/storage/:container/:blob
router.delete("/:container/:blob", deleteBlob);

export default router;
