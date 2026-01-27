// easyway-portal-api/src/routes/users.ts

import { Router } from "express";
import { getUsers, createUser, updateUser, deleteUser } from "../controllers/usersController";
import { validateParams, validateBody } from '../middleware/validate';
import { userCreateSchema,userIdParamSchema,  userUpdateSchema } from "../validators/userValidator";



const router = Router();

/**
 * GET /api/users
 * Restituisce la lista utenti del tenant corrente
 */
router.get("/", getUsers);

/**
 * POST /api/users
 * Crea un nuovo utente per il tenant corrente (validazione avanzata)
 */
router.post("/", validateBody(userCreateSchema), createUser);

/**
 * PUT /api/users/:user_id
 * Aggiorna un utente per il tenant corrente (validazione avanzata)
 */
router.put("/:user_id",  validateParams(userIdParamSchema), validateBody(userUpdateSchema), updateUser);

/**
 * DELETE /api/users/:user_id
 * Disattiva (soft delete) un utente per il tenant corrente
 */
router.delete("/:user_id", validateParams(userIdParamSchema),deleteUser);


export default router;
